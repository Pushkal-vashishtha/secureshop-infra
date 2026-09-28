data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_iam_role" "lab" {
  name = "secureshop-lab"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

# Least privilege: ESO reads only /secureshop/* parameters
resource "aws_iam_role_policy" "lab_params" {
  role = aws_iam_role.lab.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow",
        Action = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
      Resource = "arn:aws:ssm:ap-south-1:${data.aws_caller_identity.current.account_id}:parameter/secureshop/*" },
      { Effect   = "Allow",
        Action   = "kms:Decrypt",
        Resource = "*",
      Condition = { StringEquals = { "kms:ViaService" = "ssm.ap-south-1.amazonaws.com" } } }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.lab.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" # for SSM Session Manager later
}

resource "aws_iam_instance_profile" "lab" {
  name = "secureshop-lab"
  role = aws_iam_role.lab.name
}

resource "aws_instance" "lab" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.lab_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.lab.id]
  iam_instance_profile   = aws_iam_instance_profile.lab.name
  key_name               = var.key_name

  metadata_options {
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # lets the ESO pod reach IMDS; other pods are blocked by NetworkPolicy
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 40
    encrypted   = true
  }

  user_data = replace(file("${path.module}/k3s-bootstrap.sh"), "\r\n", "\n")
  tags      = { Name = "secureshop-lab", Owner = "pushkal" }
}

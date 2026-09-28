module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "secureshop-lite"
  cidr = "10.30.0.0/16"
  azs  = ["ap-south-1a", "ap-south-1b"]

  public_subnets               = ["10.30.1.0/24"]                   # lab box only
  database_subnets             = ["10.30.21.0/24", "10.30.22.0/24"] # RDS needs two AZs
  create_database_subnet_group = true

  enable_nat_gateway      = false # the big saving
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true
}

resource "aws_security_group" "lab" {
  name   = "secureshop-lab"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH from my IP only (replace with SSM later)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }
  ingress {
    description = "HTTPS for the web tier"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP for Lets Encrypt challenge and redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "secureshop-db"
  vpc_id = module.vpc.vpc_id

  ingress {
    description     = "Postgres only from the lab box"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lab.id]
  }
}

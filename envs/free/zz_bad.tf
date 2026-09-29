resource "aws_security_group" "bad" {
  name        = "bad-ssh"
  description = "test only"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

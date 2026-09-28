resource "aws_db_parameter_group" "pg" {
  name   = "secureshop-pg18"
  family = "postgres18"

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "db" {
  identifier        = "secureshop-db"
  engine            = "postgres"
  engine_version    = "18"
  instance_class    = "db.t4g.micro"
  availability_zone = "ap-south-1c"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "secureshop"
  username                    = "db_admin"
  manage_master_user_password = true

  publicly_accessible    = false
  multi_az               = false
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.pg.name

  backup_retention_period    = 1
  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true

  tags = { Name = "secureshop-db", Tier = "data" }
}

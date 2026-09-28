output "public_ip" {
  value = aws_instance.lab.public_ip
}

output "instance_id" {
  value = aws_instance.lab.id
}

output "db_address" {
  value = aws_db_instance.db.address
}

output "db_master_secret_arn" {
  value = aws_db_instance.db.master_user_secret[0].secret_arn
}

output "db_address" { value = aws_db_instance.this.address }
output "db_endpoint" { value = aws_db_instance.this.endpoint }
output "db_port" { value = aws_db_instance.this.port }
output "db_name" { value = aws_db_instance.this.db_name }
output "db_secret_arn" {
  value     = aws_secretsmanager_secret.db.arn
  sensitive = true
}
output "db_subnet_group" { value = aws_db_subnet_group.this.name }
output "db_identifier" { value = aws_db_instance.this.identifier }

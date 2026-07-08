output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.banking_db.arn
}

output "secret_name" {
  description = "Name (path) of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.banking_db.name
}

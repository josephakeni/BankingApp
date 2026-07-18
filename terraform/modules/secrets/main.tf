resource "aws_secretsmanager_secret" "banking_db" {
  name                    = var.secret_name
  description             = "PostgreSQL credentials for the TechBleat Banking application"
  recovery_window_in_days = 7

  tags = var.tags
}

# Terraform creates the secret shell only. The actual credentials are written
# by CI via `aws secretsmanager put-secret-value` using the DB_PASSWORD GitHub
# secret. The ignore_changes lifecycle prevents Terraform from ever overwriting
# or reading back the real value, so the password is never in Terraform state.
resource "aws_secretsmanager_secret_version" "banking_db" {
  secret_id = aws_secretsmanager_secret.banking_db.id

  secret_string = jsonencode({
    "postgres-username" = var.db_username
    "postgres-password" = "REPLACE_BY_CI"
    "postgres-db"       = var.db_name
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

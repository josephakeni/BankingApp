resource "aws_secretsmanager_secret" "banking_db" {
  name                    = var.secret_name
  description             = "PostgreSQL credentials for the TechBleat Banking application"
  recovery_window_in_days = 7

  tags = var.tags
}

# Placeholder value — overwrite with real credentials using the CLI command in CLAUDE.md
# before applying k8s manifests. The ignore_changes lifecycle prevents Terraform from
# reverting manual secret updates.
resource "aws_secretsmanager_secret_version" "placeholder" {
  secret_id = aws_secretsmanager_secret.banking_db.id

  secret_string = jsonencode({
    "postgres-username" = "bankuser"
    "postgres-password" = "REPLACE_BEFORE_USE"
    "postgres-db"       = "bankingdb"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

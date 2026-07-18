variable "secret_name" {
  description = "AWS Secrets Manager secret path (e.g. banking/db-credentials)"
  type        = string
  default     = "banking/db-credentials"
}

variable "db_username" {
  description = "PostgreSQL username written into the initial secret placeholder"
  type        = string
  default     = "bankuser"
}

variable "db_name" {
  description = "PostgreSQL database name written into the initial secret placeholder"
  type        = string
  default     = "bankingdb"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

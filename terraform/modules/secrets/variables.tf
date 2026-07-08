variable "secret_name" {
  description = "AWS Secrets Manager secret path (e.g. banking/db-credentials)"
  type        = string
  default     = "banking/db-credentials"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

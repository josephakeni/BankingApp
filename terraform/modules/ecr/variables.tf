variable "repository_names" {
  description = "List of ECR repository names to create (supports namespaced names like techbleat/user-service)"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

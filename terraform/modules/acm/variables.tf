variable "domain_name" {
  description = "Primary domain for the certificate (e.g. jotonialogistics.com)"
  type        = string
}

variable "use_route53" {
  description = "When true, creates Route 53 records and waits for validation. When false, outputs records for manual DNS entry."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "alb_hostname" {
  description = "ALB DNS hostname to create an ALIAS record for the apex domain. Leave empty to skip."
  type        = string
  default     = ""
}

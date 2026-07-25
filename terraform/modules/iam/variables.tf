variable "cluster_name" {
  description = "EKS cluster name — used to scope IAM role names"
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN — used in the GitHub Actions EKS describe policy"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN — used to construct IRSA trust policies"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/name format (e.g. josephakeni/BankingApp)"
  type        = string
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs that the GitHub Actions role may push to"
  type        = list(string)
}

variable "secrets_manager_arns" {
  description = "ARNs of Secrets Manager secrets the External Secrets IRSA role may read"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID — scopes the ChangeResourceRecordSets permission for the GitHub Actions role"
  type        = string
  default     = ""
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub Actions OIDC provider. Set to false when another environment root has already created it in this AWS account; the existing provider is looked up via data source instead."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

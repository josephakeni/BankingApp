output "repository_urls" {
  description = "Map of repository name → full ECR URL"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "List of ECR repository ARNs (used for IAM push policy)"
  value       = [for v in aws_ecr_repository.this : v.arn]
}

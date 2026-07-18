# ---------------------------------------------------------------------------
# Post-apply reference values (see CLAUDE.md → Terraform → Key outputs)
# ---------------------------------------------------------------------------

output "update_kubeconfig_command" {
  description = "Run this after apply to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "eks_cluster_endpoint" {
  description = "EKS API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "certificate_arn" {
  description = "ACM certificate ARN — paste into k8s/ingress.yaml"
  value       = module.acm.certificate_arn
}

output "acm_validation_records" {
  description = "DNS CNAME records to add at registrar for certificate validation (use_route53=false only)"
  value       = module.acm.validation_records
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets Operator — paste into k8s/external-secrets/serviceaccount.yaml"
  value       = module.iam.external_secrets_role_arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — set as AWS_ROLE_ARN GitHub secret"
  value       = module.iam.github_actions_role_arn
}

output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = module.iam.alb_controller_role_arn
}

output "ecr_registry" {
  description = "ECR registry base URL — used in k8s/apps/*.yaml image references and CI"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repository_urls" {
  description = "Full ECR repository URLs keyed by repository name"
  value       = module.ecr.repository_urls
}

output "nat_public_ips" {
  description = "Elastic IPs of the NAT Gateways — whitelist these at any external services that restrict by IP"
  value       = module.nat.nat_public_ips
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID — used by CI to update the ALB alias record after ingress provisioning"
  value       = var.route53_zone_id
}

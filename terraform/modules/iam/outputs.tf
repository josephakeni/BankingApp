output "alb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = module.alb_controller_irsa.arn
}

output "external_secrets_role_arn" {
  description = "IRSA role ARN for External Secrets Operator — paste into k8s/external-secrets/serviceaccount.yaml"
  value       = module.external_secrets_irsa.arn
}

output "ebs_csi_driver_role_arn" {
  description = "IRSA role ARN for the EBS CSI driver"
  value       = module.ebs_csi_irsa.arn
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC — set as AWS_ROLE_ARN GitHub secret"
  value       = aws_iam_role.github_actions.arn
}

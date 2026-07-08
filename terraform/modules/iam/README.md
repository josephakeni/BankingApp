# Module: iam

Creates all IAM roles required by the banking platform:

| Role | Mechanism | Used by |
|------|-----------|---------|
| `alb-controller-*` | IRSA | AWS Load Balancer Controller (Helm) |
| `external-secrets-*` | IRSA | External Secrets Operator (Helm) |
| `ebs-csi-driver-*` | IRSA | EBS CSI driver addon |
| `github-actions-*` | OIDC | GitHub Actions CI/CD pipeline |

IRSA roles are built with
[terraform-aws-modules/iam//modules/iam-role-for-service-accounts-eks](https://registry.terraform.io/modules/terraform-aws-modules/iam/aws/latest/submodules/iam-role-for-service-accounts-eks)
`~> 6.6` which bundles the correct AWS-managed and community-maintained policies.

## Usage

```hcl
module "iam" {
  source = "./modules/iam"

  cluster_name        = module.eks.cluster_name
  cluster_arn         = module.eks.cluster_arn
  oidc_provider_arn   = module.eks.oidc_provider_arn
  github_repo         = "josephakeni/BankingApp"
  ecr_repository_arns = module.ecr.repository_arns
  tags                = local.tags
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| cluster_name | EKS cluster name (used in role name suffix) | `string` | yes |
| cluster_arn | EKS cluster ARN (EKS describe policy) | `string` | yes |
| oidc_provider_arn | OIDC provider ARN from EKS module | `string` | yes |
| github_repo | GitHub repo in `owner/name` format | `string` | yes |
| ecr_repository_arns | ECR repo ARNs for push policy | `list(string)` | yes |
| tags | Tags for all resources | `map(string)` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_controller_role_arn | ALB controller IRSA role ARN |
| external_secrets_role_arn | ESO IRSA role ARN — paste into `k8s/external-secrets/serviceaccount.yaml` |
| ebs_csi_driver_role_arn | EBS CSI IRSA role ARN |
| github_actions_role_arn | GitHub Actions role ARN — set as `AWS_ROLE_ARN` GitHub secret |

# Module: eks

Provisions the `techbleat-banking` EKS cluster and its managed node group using
[terraform-aws-modules/eks/aws](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
`~> 21.23`.

Core managed addons installed: `coredns`, `kube-proxy`, `vpc-cni`,
`eks-pod-identity-agent`. The `aws-ebs-csi-driver` addon is created separately
in the root `main.tf` so its IRSA role ARN (from the IAM module) can be
injected without creating a circular dependency.

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name       = "techbleat-banking"
  kubernetes_version = "1.33"
  vpc_id             = module.networking.vpc_id
  subnet_ids         = var.private_subnet_ids

  node_instance_type = "t3.medium"
  node_desired_size  = 2
  node_min_size      = 1
  node_max_size      = 4

  tags = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | EKS cluster name | `string` | n/a | yes |
| kubernetes_version | Kubernetes version | `string` | `"1.33"` | no |
| vpc_id | VPC ID for security group | `string` | n/a | yes |
| subnet_ids | Private subnet IDs for node placement | `list(string)` | n/a | yes |
| node_instance_type | Worker node EC2 type | `string` | `"t3.medium"` | no |
| node_desired_size | Desired node count | `number` | `2` | no |
| node_min_size | Minimum node count | `number` | `1` | no |
| node_max_size | Maximum node count | `number` | `4` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | EKS cluster name |
| cluster_endpoint | Kubernetes API server endpoint |
| cluster_arn | EKS cluster ARN |
| cluster_version | Active Kubernetes version |
| cluster_certificate_authority_data | Base64-encoded CA certificate (sensitive) |
| oidc_provider_arn | OIDC provider ARN for IRSA |
| cluster_security_group_id | Cluster security group ID |
| node_security_group_id | Node shared security group ID |

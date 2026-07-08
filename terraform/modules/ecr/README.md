# Module: ecr

Creates one ECR repository per service and attaches a lifecycle policy that
retains the 10 most recent images.

Repositories created:
- `techbleat/user-service`
- `techbleat/transaction-service`
- `techbleat/activity-service`
- `techbleat/frontend`

## Usage

```hcl
module "ecr" {
  source = "./modules/ecr"

  repository_names = [
    "techbleat/user-service",
    "techbleat/transaction-service",
    "techbleat/activity-service",
    "techbleat/frontend",
  ]

  tags = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| repository_names | ECR repository names to create | `list(string)` | n/a | yes |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_urls | Map of name → full ECR URL |
| repository_arns | List of repository ARNs (used by IAM push policy) |

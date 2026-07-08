# Module: networking

Read-only module. Looks up the existing `main_vpc` VPC by its `Name` tag and
exposes its ID for downstream modules. Subnets are passed explicitly via
`terraform.tfvars` rather than discovered here, per project convention.

## Usage

```hcl
module "networking" {
  source   = "./modules/networking"
  vpc_name = "main_vpc"
  tags     = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_name | Name tag of the existing VPC | `string` | `"main_vpc"` | no |
| tags | Tags to propagate | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the main VPC |
| vpc_cidr | CIDR block of the main VPC |

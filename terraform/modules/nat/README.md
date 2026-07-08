## Purpose

Adds outbound internet access to private subnets in an existing VPC by creating
one NAT Gateway per Availability Zone. Each private subnet is routed through its
own AZ-local NAT Gateway to prevent cross-AZ traffic charges and eliminate single
points of failure.

Resources created:
- 2 Elastic IPs (one per AZ)
- 2 NAT Gateways placed in the provided public subnets
- 1 `aws_route` added to the existing eu-west-1a private route table
- 1 new `aws_route_table` for eu-west-1b with a `0.0.0.0/0` → NAT route
- 1 `aws_route_table_association` moving the eu-west-1b private subnet to the new table

## Usage

```hcl
module "nat" {
  source = "./modules/nat"

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = slice(var.public_subnet_ids, 0, 2)
  private_subnet_ids = var.private_subnet_ids
  tags               = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | ID of the VPC | `string` | — | yes |
| public_subnet_ids | Two public subnet IDs (one per AZ) for NAT Gateway placement | `list(string)` | — | yes |
| private_subnet_ids | Two private subnet IDs (one per AZ) that need outbound internet | `list(string)` | — | yes |
| tags | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| nat_gateway_ids | NAT Gateway IDs (index 0 = eu-west-1a, 1 = eu-west-1b) |
| nat_public_ips | Elastic IP addresses assigned to each NAT Gateway |

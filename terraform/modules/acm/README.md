# Module: acm

Requests an ACM certificate for `jotonialogistics.com` (plus `*.jotonialogistics.com`
as a SAN) using DNS validation.

Two modes controlled by `use_route53`:

| `use_route53` | Behaviour |
|---------------|-----------|
| `false` (default) | Certificate is requested; validation CNAME records are output for manual entry at the registrar |
| `true` | Route 53 records are created and `aws_acm_certificate_validation` waits for AWS to validate |

Because this project uses `use_route53 = false`, apply is a two-step process
(see CLAUDE.md → Terraform section).

## Usage

```hcl
module "acm" {
  source = "./modules/acm"

  domain_name = "jotonialogistics.com"
  use_route53 = false
  tags        = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain_name | Primary domain for the certificate | `string` | n/a | yes |
| use_route53 | Auto-validate via Route 53 | `bool` | `false` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ACM certificate ARN — paste into `k8s/ingress.yaml` |
| validation_records | DNS CNAME records to add at registrar (empty when `use_route53=true`) |

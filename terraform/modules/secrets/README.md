# Module: secrets

Creates the `banking/db-credentials` AWS Secrets Manager secret consumed by
the External Secrets Operator.

A placeholder secret version is created on first apply so the resource exists
before the ESO tries to read it. The `ignore_changes` lifecycle rule prevents
Terraform from overwriting real credentials added via the CLI.

## Populate credentials after apply

```bash
aws secretsmanager put-secret-value \
  --region eu-west-1 \
  --secret-id banking/db-credentials \
  --secret-string '{"postgres-username":"bankuser","postgres-password":"STRONG_PASSWORD","postgres-db":"bankingdb"}'
```

## Usage

```hcl
module "secrets" {
  source      = "./modules/secrets"
  secret_name = "banking/db-credentials"
  tags        = local.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| secret_name | Secrets Manager secret path | `string` | `"banking/db-credentials"` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arn | ARN of the Secrets Manager secret |
| secret_name | Path/name of the secret |

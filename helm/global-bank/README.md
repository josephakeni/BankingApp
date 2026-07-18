## Purpose
Deploys the Global Banking Application to an EKS cluster. Covers the `banking` namespace, ConfigMap, StorageClass, ALB Ingress, four application microservices, three datastore StatefulSets (Postgres, Redis, Kafka), and External Secrets resources.

## Usage
```hcl
# Install / upgrade
helm upgrade --install global-bank ./helm/global-bank \
  --namespace banking \
  --create-namespace \
  --set ingress.certificateArn=<acm-arn> \
  --set userService.image.tag=<git-sha>
```

To deploy a specific image tag across all services:
```bash
helm upgrade global-bank ./helm/global-bank \
  --namespace banking \
  --set frontend.image.tag=abc1234 \
  --set userService.image.tag=abc1234 \
  --set transactionService.image.tag=abc1234 \
  --set activityService.image.tag=abc1234
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `ingress.host` | Public hostname for the ALB ingress | string | `brightstaraid.org` | no |
| `ingress.certificateArn` | ACM certificate ARN for HTTPS | string | `""` | **yes** |
| `configmap.frontendOrigin` | CORS origin returned to services | string | `https://brightstaraid.org` | no |
| `configmap.databaseUrl` | Postgres connection string for Python services | string | see values.yaml | no |
| `configmap.springDatasourceUrl` | Postgres JDBC URL for transaction-service | string | see values.yaml | no |
| `frontend.image.tag` | Frontend container image tag | string | `latest` | no |
| `userService.image.tag` | user-service container image tag | string | `latest` | no |
| `transactionService.image.tag` | transaction-service container image tag | string | `latest` | no |
| `activityService.image.tag` | activity-service container image tag | string | `latest` | no |
| `postgres.storage` | PVC size for Postgres | string | `10Gi` | no |
| `redis.storage` | PVC size for Redis | string | `2Gi` | no |
| `kafka.storage` | PVC size for Kafka | string | `10Gi` | no |
| `kafka.clusterId` | KRaft cluster ID — do not change after first deploy | string | `MkU3OEVBNTcwNTJENDM2Qk` | no |
| `externalSecrets.region` | AWS region for Secrets Manager | string | `eu-west-1` | no |
| `externalSecrets.awsSecretKey` | Secrets Manager secret name | string | `banking/db-credentials` | no |

## Outputs
| Name | Description |
|------|-------------|
| n/a | Use `kubectl get ingress banking-ingress -n banking -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'` to retrieve the ALB hostname after install |

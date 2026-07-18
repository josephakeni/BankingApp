data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Helm provider — connects to the EKS cluster using AWS CLI token auth.
# The exec command is evaluated lazily at apply time (not plan), so this
# works on fresh deployments where the cluster doesn't exist yet.
# ---------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.aws_region]
    }
  }
}

locals {
  tags = {
    Project     = "techbleat-banking"
    Environment = "production"
  }

  ecr_repository_names = [
    "techbleat/user-service",
    "techbleat/transaction-service",
    "techbleat/activity-service",
    "techbleat/frontend",
  ]
}

# ---------------------------------------------------------------------------
# Networking — looks up main_vpc; subnets are passed explicitly via tfvars
# ---------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  vpc_name = "main_vpc"
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# NAT Gateways — one per AZ so private-subnet worker nodes can reach ECR,
# the EKS API endpoint, and package mirrors. Must exist before EKS node
# group bootstrapping starts.
# ---------------------------------------------------------------------------
module "nat" {
  source = "./modules/nat"

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = slice(var.public_subnet_ids, 0, 2)
  private_subnet_ids = var.private_subnet_ids
  tags               = local.tags
}

# ---------------------------------------------------------------------------
# EKS cluster + core managed addons
# ---------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.networking.vpc_id
  subnet_ids         = var.private_subnet_ids

  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size

  tags = local.tags
}

# ---------------------------------------------------------------------------
# IAM — IRSA roles + GitHub Actions OIDC
# EKS must be applied first so oidc_provider_arn is available.
# ---------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  cluster_name         = module.eks.cluster_name
  cluster_arn          = module.eks.cluster_arn
  oidc_provider_arn    = module.eks.oidc_provider_arn
  github_repo          = var.github_repo
  ecr_repository_arns  = module.ecr.repository_arns
  secrets_manager_arns = [module.secrets.secret_arn]
  route53_zone_id      = var.route53_zone_id
  tags                 = local.tags
}

# ---------------------------------------------------------------------------
# EBS CSI add-on
# Created here (not inside the eks module) to break the dependency cycle:
# EKS → oidc_arn → IAM → ebs_csi_role_arn → this resource → EKS addon
# ---------------------------------------------------------------------------
data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks.cluster_version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.eks.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn    = module.iam.ebs_csi_driver_role_arn
  resolve_conflicts_on_create = "OVERWRITE"

  tags = local.tags

  depends_on = [module.eks, module.iam]
}

# ---------------------------------------------------------------------------
# ECR repositories (4 repos, one per service)
# ---------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  repository_names = local.ecr_repository_names
  tags             = local.tags
}

# ---------------------------------------------------------------------------
# ACM certificate for jotonialogistics.com (+ wildcard SAN)
# ---------------------------------------------------------------------------
module "acm" {
  source = "./modules/acm"

  domain_name  = var.domain_name
  use_route53  = var.use_route53
  alb_hostname = var.alb_hostname
  tags         = local.tags
}

# ---------------------------------------------------------------------------
# EKS access entry — grants the GitHub Actions role kubectl permissions
# so CI can run kubectl set image after building and pushing images.
# ---------------------------------------------------------------------------
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.github_actions_role_arn
  type          = "STANDARD"

  tags = local.tags
}

resource "aws_eks_access_policy_association" "github_actions_edit" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["banking"]
  }

  depends_on = [aws_eks_access_entry.github_actions]
}

resource "aws_eks_access_policy_association" "github_actions_cluster_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = module.iam.github_actions_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.github_actions]
}

# ---------------------------------------------------------------------------
# AWS Secrets Manager — banking/db-credentials
# ---------------------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"

  secret_name = var.db_secret_name
  db_username = var.db_username
  db_name     = var.db_name
  tags        = local.tags
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller — installed via Helm after EKS + IAM exist.
# VPC ID and region are passed explicitly to avoid IMDS discovery failures.
# ---------------------------------------------------------------------------
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.13.2"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "region"
    value = var.aws_region
  }
  set {
    name  = "vpcId"
    value = module.networking.vpc_id
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.alb_controller_role_arn
  }

  depends_on = [module.eks, module.iam]
}

# ---------------------------------------------------------------------------
# External Secrets Operator — installed via Helm after the ALB controller is
# fully ready. ESO's install triggers the ALB controller's mutating webhook
# (mservice.elbv2.k8s.aws), so the controller pods must be running first.
# The ESO controller service account is annotated with the IRSA role so it
# can authenticate to AWS Secrets Manager without explicit auth in the
# ClusterSecretStore.
# ---------------------------------------------------------------------------
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  namespace        = "external-secrets"
  version          = "0.18.2"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.external_secrets_role_arn
  }

  depends_on = [module.eks, module.iam, helm_release.alb_controller]
}

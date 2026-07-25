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
  # Prod has no suffix so existing resource names (ECR repos, IAM roles) are
  # preserved. All other environments append "-<env>".
  env_suffix = var.environment == "prod" ? "" : "-${var.environment}"

  tags = {
    Project     = "techbleat-banking"
    Environment = var.environment
  }

  ecr_repository_names = [
    "techbleat/user-service${local.env_suffix}",
    "techbleat/transaction-service${local.env_suffix}",
    "techbleat/activity-service${local.env_suffix}",
    "techbleat/frontend${local.env_suffix}",
  ]
}

# ---------------------------------------------------------------------------
# Networking — looks up main_vpc; subnets are passed explicitly via tfvars
# ---------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  vpc_name = "main_vpc"
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# NAT Gateways — one per AZ so private-subnet worker nodes can reach ECR,
# the EKS API endpoint, and package mirrors.
# Set create_nat_gateways = false in environments that share subnets with
# prod to avoid conflicting route table associations on the same subnets.
# ---------------------------------------------------------------------------
module "nat" {
  count  = var.create_nat_gateways ? 1 : 0
  source = "../../modules/nat"

  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = slice(var.public_subnet_ids, 0, 2)
  private_subnet_ids = var.private_subnet_ids
  tags               = local.tags
}

# ---------------------------------------------------------------------------
# EKS cluster + core managed addons
# ---------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

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
  source = "../../modules/iam"

  cluster_name                = module.eks.cluster_name
  cluster_arn                 = module.eks.cluster_arn
  oidc_provider_arn           = module.eks.oidc_provider_arn
  github_repo                 = var.github_repo
  ecr_repository_arns         = module.ecr.repository_arns
  secrets_manager_arns        = [module.secrets.secret_arn]
  route53_zone_id             = var.route53_zone_id
  create_github_oidc_provider = var.create_github_oidc_provider
  tags                        = local.tags
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
  source = "../../modules/ecr"

  repository_names = local.ecr_repository_names
  tags             = local.tags
}

# ---------------------------------------------------------------------------
# ACM certificate
# ---------------------------------------------------------------------------
module "acm" {
  source = "../../modules/acm"

  domain_name     = var.domain_name
  use_route53     = var.use_route53
  alb_hostname    = var.alb_hostname
  route53_zone_id = var.route53_zone_id
  tags            = local.tags
}

# ---------------------------------------------------------------------------
# EKS access entry — grants the GitHub Actions role kubectl permissions
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
# AWS Secrets Manager — database credentials shell
# ---------------------------------------------------------------------------
module "secrets" {
  source = "../../modules/secrets"

  secret_name = var.db_secret_name
  db_username = var.db_username
  db_name     = var.db_name
  tags        = local.tags
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller — installed via Helm after EKS + IAM exist.
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
# External Secrets Operator
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

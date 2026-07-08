module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.23"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_public_access  = true
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  # Core managed addons — EBS CSI is provisioned separately in root main.tf
  # to avoid a circular dependency with the IAM IRSA role.
  addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    default = {
      name           = "${var.cluster_name}-ng"
      instance_types = [var.node_instance_type]
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size

      # Nodes need enough capacity to run: Postgres, Redis, Kafka (StatefulSets)
      # + user-service, transaction-service, activity-service, frontend (Deployments)
      disk_size = 50
    }
  }

  tags = var.tags
}

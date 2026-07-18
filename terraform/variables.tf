variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "techbleat-banking"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.33"
}

variable "private_subnet_ids" {
  description = "Subnet IDs for EKS worker nodes (private, from main_vpc)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Subnet IDs for the ALB (public, from main_vpc)"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "domain_name" {
  description = "Primary domain for the ACM certificate and ALB"
  type        = string
  default     = "jotonialogistics.com"
}

variable "use_route53" {
  description = "When true, validates ACM cert via Route 53 automatically. When false, outputs DNS records for manual validation."
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repository in owner/name format for OIDC trust (e.g. josephakeni/BankingApp)"
  type        = string
  default     = "josephakeni/BankingApp"
}

variable "db_secret_name" {
  description = "AWS Secrets Manager secret path for database credentials"
  type        = string
  default     = "banking/db-credentials"
}

variable "alb_hostname" {
  description = "ALB hostname provisioned by the AWS Load Balancer Controller (from kubectl get ingress)"
  type        = string
  default     = ""
}

variable "db_username" {
  description = "PostgreSQL username stored in Secrets Manager"
  type        = string
  default     = "bankuser"
}

variable "db_name" {
  description = "PostgreSQL database name stored in Secrets Manager"
  type        = string
  default     = "bankingdb"
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID for the domain — used by CI to update the ALB alias record"
  type        = string
  default     = ""
}

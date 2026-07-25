terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.50"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }

  # State key is intentionally unchanged from the original root so no state
  # migration is required. Running `terraform init` here picks up the existing
  # state file directly.
  backend "s3" {
    bucket       = "aacloudagentic"
    key          = "agentic/aws/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "techbleat-banking"
      ManagedBy = "terraform"
    }
  }
}

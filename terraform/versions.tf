terraform {
  # 1.10.0 is the minimum required for native S3 state locking (use_lockfile).
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

  # Remote state — all modules in this project share this single state file.
  # Native S3 locking (use_lockfile) writes a .tflock object alongside the
  # state file; no DynamoDB table is required.
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

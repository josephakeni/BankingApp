# CLAUDE.md — Global Bank Terraform Project

This file defines the rules, conventions, and workflows that Claude Code must follow
when working in this repository. All instructions here are mandatory and override
default behaviour.

---

## Project Overview

This repository provisions AWS infrastructure using Terraform. All infrastructure is
modular, version-pinned, and deployed to `eu-west-1`. The project targets an EKS-based
architecture under the `agentic` project tag in the `dev` environment.

---

## Repository Structure

Organise Terraform code as follows. Every deployable unit lives inside `modules/`.
Root-level `main.tf` composes modules; it does not contain inline resource definitions.

```
.
├── main.tf               # Root composition — calls modules only
├── variables.tf
├── outputs.tf
├── versions.tf           # Required providers and Terraform version constraints
├── terraform.tfvars
└── modules/
    ├── networking/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── eks/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    └── <other-modules>/
        └── README.md
```

---

## Terraform Workflow

Follow this sequence for every change. Do not skip or reorder steps.

### 1. Format

```bash
terraform fmt --recursive
```

This must produce **no diff**. Fix any formatting issues before continuing.

### 2. Validate

```bash
terraform validate
```

Must report `Success! The configuration is valid.` Fix all errors before continuing.

### 3. Plan

```bash
terraform plan -out=tfplan
```

Must succeed with no errors. After the plan completes:

- Display the **add / change / destroy** summary table to the user.
- Highlight any resource marked `-/+` (replace) explicitly.
- **If any resource is marked `-/+`, stop and ask the user for explicit written
  confirmation before proceeding.** Do not continue automatically.

### 4. Review & Confirm

Wait for the user to review the plan output. Only proceed to push once the user
has confirmed the plan is acceptable.

### 5. Push

```bash
git push
```

Use the SSH key at `~/.ssh/id_rsa` for all Git operations. Ensure the remote URL
uses SSH (`git@github.com:...`), not HTTPS.

---

## Safety Rules

These are hard stops. Never bypass them.

| Rule | Detail |
|------|--------|
| **Never run `terraform destroy`** | Under any circumstances, in any environment. |
| **Never push before a successful plan** | `terraform plan` must succeed locally first. |
| **Always confirm replacements** | Any `-/+` resource requires explicit user confirmation before the workflow continues. |
| **Never auto-apply** | Do not run `terraform apply` unless the user explicitly requests it after reviewing the plan. |
| **Never skip `terraform fmt`** | Format must be clean before plan or push. |

---

## Pre-Push Checklist

Run these steps in order before every `git push`. All must pass.

- [ ] `terraform fmt --recursive` — produces no diff
- [ ] `terraform validate` — reports success
- [ ] `terraform plan -out=tfplan` — succeeds, output reviewed by user
- [ ] Summary table displayed (resources to add / change / destroy)
- [ ] If any `-/+` (replace) resource exists — **explicit user confirmation received**
- [ ] User has approved the plan
- [ ] `git push` using SSH key at `~/.ssh/id_rsa`

---

## AWS Defaults

Use these values unless the user explicitly overrides them.

| Setting | Value |
|---------|-------|
| Region | `eu-west-1` |
| Default EC2 instance type | `t2.micro` |
| Associate public IP | `true` |

### Mandatory Tags

Apply these tags to **every** resource and module:

```hcl
tags = {
  Project     = "agentic"
  Environment = "dev"
}
```

### Naming Convention

```
agentic-{resource-type}-{env}
```

Examples:
- `agentic-eks-cluster-dev`
- `agentic-vpc-dev`
- `agentic-sg-dev`
- `agentic-rds-dev`

---

## Networking

- Use the existing VPC named `main_vpc` as the default network.
- Reference its subnets via data sources (`data "aws_subnet_ids"` or
  `data "aws_subnets"`) rather than hardcoding IDs.
- Create new subnets within `main_vpc` only when required by a module.
- Do not create a new VPC unless the user explicitly requests one.

---

## Conventions

### Use terraform-aws-modules

Prefer published modules from the [Terraform Registry](https://registry.terraform.io)
over writing raw resources. Common modules to use:

| Purpose | Module |
|---------|--------|
| EKS | `terraform-aws-modules/eks/aws` |
| VPC | `terraform-aws-modules/vpc/aws` |
| RDS | `terraform-aws-modules/rds/aws` |
| Security Groups | `terraform-aws-modules/security-group/aws` |
| IAM | `terraform-aws-modules/iam/aws` |

Always pin the module version. Before using any module, call
`get_latest_module_version` (Terraform MCP tool) to confirm the current stable
release, then hard-pin it:

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"   # pin to a specific minor series
  ...
}
```

### Provider Version Pinning

Pin all providers in `versions.tf`. Call `get_latest_provider_version` before
writing version constraints.

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Module Structure Rules

- Every module must expose `variables.tf` and `outputs.tf`.
- Every module must have a `README.md` (see Documentation section).
- Modules must not call other local modules (keep the dependency graph flat).
- Pass the mandatory tags into every module via a `tags` variable; merge with
  module-specific tags using `merge()`.

---

## Documentation

Every module directory must contain a `README.md` with the following sections:

```markdown
## Purpose
What this module creates and why.

## Usage
\`\`\`hcl
module "example" {
  source = "./modules/<name>"
  ...
}
\`\`\`

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|

## Outputs
| Name | Description |
|------|-------------|
```

Update the module README whenever inputs or outputs change.

---

## Post-Apply: EKS Cluster

After `terraform apply` completes and an EKS cluster has been created or updated,
retrieve and display the cluster's public endpoint so the user can open it in a
browser:

```bash
terraform output eks_cluster_endpoint
```

Present the URL clearly, e.g.:

```
EKS cluster is ready.
Endpoint: https://<cluster-endpoint>
```

---

## Git & SSH

- All Git operations must use the SSH key at `~/.ssh/id_rsa`.
- Verify the remote is SSH-based before pushing:
  ```bash
  git remote -v
  ```
- If the remote uses HTTPS, switch it to SSH before pushing.
- Commit messages should be concise and imperative, e.g.:
  `add eks module with managed node group`

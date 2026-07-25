# The IAM module now uses count on the GitHub OIDC provider so it can be
# skipped in environments where it already exists. These moved blocks tell
# Terraform that the singleton resources in the existing state map to index [0]
# — preventing an unnecessary destroy + recreate on the first plan.
moved {
  from = module.iam.aws_iam_openid_connect_provider.github
  to   = module.iam.aws_iam_openid_connect_provider.github[0]
}

moved {
  from = module.nat
  to   = module.nat[0]
}

output "certificate_arn" {
  description = "ACM certificate ARN — paste into k8s/ingress.yaml"
  value       = aws_acm_certificate.banking.arn
}

output "validation_records" {
  description = "DNS CNAME records required to validate the certificate (empty when use_route53=true)"
  value = var.use_route53 ? [] : [
    for dvo in aws_acm_certificate.banking.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}

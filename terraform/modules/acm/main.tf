resource "aws_acm_certificate" "banking" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

# Automatic validation via Route 53 (only when use_route53 = true).
# Zone lookup is skipped when route53_zone_id is supplied directly — required
# for subdomains (e.g. dev.example.com) where the hosted zone is the apex.
data "aws_route53_zone" "this" {
  count = var.use_route53 && var.route53_zone_id == "" ? 1 : 0

  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.use_route53 ? (
    var.route53_zone_id != "" ? var.route53_zone_id : data.aws_route53_zone.this[0].zone_id
  ) : ""
}

resource "aws_route53_record" "validation" {
  for_each = var.use_route53 ? {
    for dvo in aws_acm_certificate.banking.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id         = local.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "banking" {
  count = var.use_route53 ? 1 : 0

  certificate_arn         = aws_acm_certificate.banking.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

# ALIAS record → ALB (created once the ALB hostname is known)
resource "aws_route53_record" "apex_alb" {
  count = var.use_route53 && var.alb_hostname != "" ? 1 : 0

  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_hostname
    zone_id                = "Z32O12XQLNTSW2" # eu-west-1 ELB hosted zone ID
    evaluate_target_health = true
  }
}

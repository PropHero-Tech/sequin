# SSL Certificate for console.sequin.prophero.com
resource "aws_acm_certificate" "sequin_console" {
  domain_name       = "console.sequin.prophero.com"
  validation_method = "DNS"

  tags = {
    Name = "sequin-console-cert"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 record for SSL certificate validation
resource "aws_route53_record" "sequin_console_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.sequin_console.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = "Z015655612M5EH93SA467"
}

# Certificate validation
resource "aws_acm_certificate_validation" "sequin_console" {
  certificate_arn         = aws_acm_certificate.sequin_console.arn
  validation_record_fqdns = [for record in aws_route53_record.sequin_console_cert_validation : record.fqdn]
}

# Route53 A record pointing to the load balancer
resource "aws_route53_record" "sequin_console" {
  zone_id = "Z015655612M5EH93SA467"
  name    = "console.sequin.prophero.com"
  type    = "A"

  alias {
    name                   = aws_lb.sequin-main.dns_name
    zone_id                = aws_lb.sequin-main.zone_id
    evaluate_target_health = true
  }
}
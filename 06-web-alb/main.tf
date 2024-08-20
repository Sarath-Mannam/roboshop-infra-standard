resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-${var.common_tags.Component}"
  internal           = false # Internal will be false because this is going to be public load balancer
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.web_alb_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.public_subnet_ids.value) # To ensure high availability, we must use at least two subnets for the Application Load Balancer (ALB)

  # enable_deletion_protection = true

  tags = var.common_tags
}

resource "aws_acm_certificate" "mannamsarath" {
  domain_name       = "mannamsarath.online"
  validation_method = "DNS"
  tags = var.common_tags
}

# This data source is getting the data from Hosted Zone
data "aws_route53_zone" "mannamsarath" {
  name         = "mannamsarath.online"
  private_zone = false
}

resource "aws_route53_record" "mannamsarath" {
  for_each = {
    for dvo in aws_acm_certificate.mannamsarath.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.mannamsarath.zone_id
} # This particular block will create the validation records 

resource "aws_acm_certificate_validation" "mannamsarath" {
  certificate_arn         = aws_acm_certificate.mannamsarath.arn
  validation_record_fqdns = [for record in aws_route53_record.mannamsarath : record.fqdn]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.web_alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.mannamsarath.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is the fixed response from Web ALB HTTPS"
      status_code  = "200"
    }
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = "mannamsarath.online"

  records = [
    {
      name    = ""
      type    = "A"
      alias   = {
        name    = aws_lb.web_alb.dns_name # DNS name of load balancer
        zone_id = aws_lb.web_alb.zone_id
      }
    }
  ]
}


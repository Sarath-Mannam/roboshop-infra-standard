resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-${var.common_tags.Component}"
  internal           = false # Internal will be false because this is going to be public load balancer
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.web_alb_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.public_subnet_ids.value) # To ensure high availability, we must use at least two subnets for the Application Load Balancer (ALB)

  # enable_deletion_protection = true

  tags = var.common_tags
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "443"
  protocol          = "HTTPS"

  # This will add one listener on port number 80 and one default rule
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is the fixed response from APP ALB"
      status_code  = "200"
    }
  }
}
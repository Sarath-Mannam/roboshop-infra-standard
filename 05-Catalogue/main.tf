resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project_name}-${var.common_tags.Component}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  health_check {
    enabled = true
    healthy_threshold = 2 # Continuously two health checks are success then you can consider as healthy
    interval = 15 # For every 15 seconds will check health of the component
    matcher = "200-299" # Any response code within this range consider it as success
    path = "/health" # will get the response if component is healthy
    port = 8080
    protocol = "HTTP"
    timeout = 5 # if there is no response within 5 seconds then consider it as failure
    unhealthy_threshold = 3 # If three consecutive requests are failed then consider as failure
  }
}

resource "aws_launch_template" "catalogue" {
  name = "${var.project_name}-${var.common_tags.Component}"
  image_id = data.aws_ami.devops_ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Catalogue"
    }
  }

  user_data = filebase64("${path.module}/catalogue.sh") # Convert text into base64-encoded user data to provide when launching the instance
}

resource "aws_autoscaling_group" "catalogue" {
  name                      = "${var.project_name}-${var.common_tags.Component}"
  max_size                  = 5
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "ELB" # Load balancer responsibility is to check health of instances
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.catalogue.arn] # Target Group
  launch_template {
    id      = aws_launch_template.catalogue.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  tag {
    key                 = "Name"
    value               = "Catalogue"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

resource "aws_autoscaling_policy" "catalogue" {
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name = "cpu"
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  condition {
    host_header {
      values = ["catalogue.app.mannamsarath.online"]
    }
  }
  # When you receive request from the above host header then forward request to the catalogue group
}
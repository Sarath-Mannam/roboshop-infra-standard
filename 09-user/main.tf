module "user" {
  source = "../../terraform-roboshop-app"
  project_name = var.project_name
  env = var.env
  common_tags = var.common_tags

  # target group
  #health_check = var.health_check
  target_group_port = var.target_group_port
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  #launch template
  image_id = data.aws_ami.devops_ami.id
  security_group_id = data.aws_ssm_parameter.user_sg_id.value
  user_data = filebase64("${path.module}/user.sh")
  launch_template_tags = var.launch_template_tags

  #AutoScaling
  vpc_zone_identifier = split(",",data.aws_ssm_parameter.private_subnet_ids.value)
  tag = var.autoscaling_tags

  #Auto Scaling Policy going with optional parameters, So mandatory parameters are not required here.

  #Listener rule
  alb_listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  rule_priority = 20 # because catalogue have 10 already
  host_header = "user.app.mannamsarath.online"
}
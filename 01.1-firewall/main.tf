
module "vpn_sg" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  sg_name = "roboshop-vpn"
  sg_description = "Allowing all ports from my home IP address" # Here will not give full Internet access
  # sg_ingress_rules = var.sg_ingress_rules # Will not give ingress rules here, So create ingress rules always separately
  #vpc_id = local.vpc_id # Here VPC ID is not --> local.vpc_id local because i have to refer from AWS parameter store but since this is default vpc so i need to fetch the default vpc with help of datasource
  vpc_id = data.aws_vpc.default.id # Since i'm creating VPN in Default VPC, So here we need default vpc id
  common_tags = merge(
    var.common_tags,
    {
        Component = "VPN"
        Name = "roboshop-VPN"
    }
  )
}

module "mongodb_sg" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  sg_name = "mongodb"
  sg_description = "Allowing traffic"
  #sg_ingress_rules = var.sg_ingress_rules
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = merge(
    var.common_tags,
    {
        Component = "MongoDB",
        Name = "MongoDB"
    }
  )
}

module "catalogue_sg" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  sg_name = "catalogue"
  sg_description = "Allowing traffic"
  #sg_ingress_rules = var.sg_ingress_rules
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = merge(
    var.common_tags,
    {
        Component = "Catalogue",
        Name = "Catalogue"
    }
  )
}

module "web_sg" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  sg_name = "web"
  sg_description = "Allowing traffic"
  #sg_ingress_rules = var.sg_ingress_rules
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = merge(
    var.common_tags,
    {
        Component = "web"
    }
  )
}

module "app_alb_sg" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  sg_name = "App-ALB"
  sg_description = "Allowing traffic"
  #sg_ingress_rules = var.sg_ingress_rules
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = merge(
    var.common_tags,
    {
        Component = "APP",
        Name = "App-ALB"
    }
  )
}

module "web_alb_sg" {
  source = "../../terraform-aws-securitygroup"
  project_name = var.project_name
  sg_name = "Web-ALB"
  sg_description = "Allowing traffic"
  #sg_ingress_rules = var.sg_ingress_rules
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  common_tags = merge(
    var.common_tags,
    {
        Component = "web",
        Name = "Web-ALB"
    }
  )
}

resource "aws_security_group_rule" "vpn" {
  # I am going to add a rule to this security group to allow all ports, but only from my IP address's CIDR block
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  # cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.vpn_sg.security_group_id 
}

# This is allowing connections from all catalogue instances to MongoDB
resource "aws_security_group_rule" "mongodb_catalogue" {
  type              = "ingress"
  description       = "Allowing port number 27017 from catalogue component"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  source_security_group_id = module.catalogue_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.mongodb_sg.security_group_id
}

# This is allowing traffic from VPN instance on Port no 22 to mongodb for troubleshooting
resource "aws_security_group_rule" "mongodb_vpn" {
  type              = "ingress"
  description       = "Allowing port number 22 from VPN component"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.mongodb_sg.security_group_id
}

resource "aws_security_group_rule" "catalogue_vpn" {
  type              = "ingress"
  description       = "Allowing port number 22 from VPN component"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.catalogue_sg.security_group_id
}

# Allow traffic from app_alb on port no 8080 to connect with catalogue 
resource "aws_security_group_rule" "catalogue_app_alb" {
  type              = "ingress"
  description       = "Allowing port number 8080 from app_alb"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.app_alb_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.catalogue_sg.security_group_id
}

resource "aws_security_group_rule" "app_alb_vpn" {
  type              = "ingress"
  description       = "Allowing port number 80 from VPN component"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.app_alb_sg.security_group_id
}

resource "aws_security_group_rule" "app_alb_web" {
  type              = "ingress"
  description       = "Allowing port number 80 from web"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.web_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.app_alb_sg.security_group_id
}

resource "aws_security_group_rule" "web_vpn" {
  type              = "ingress"
  description       = "Allowing port number 80 from VPN"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.web_sg.security_group_id
}


resource "aws_security_group_rule" "web_web_alb" {
  type              = "ingress"
  description       = "Allowing port number 80 from web ALB"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.web_alb_sg.security_group_id
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.web_sg.security_group_id
}

resource "aws_security_group_rule" "web_alb_internet" {
  type              = "ingress"
  description       = "Allowing port number 80 from Internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  #cidr_blocks       = ["${chomp(data.http.myip.response_body)}/32"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = module.web_alb_sg.security_group_id
}

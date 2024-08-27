module "mysql_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.devops_ami.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [data.aws_ssm_parameter.mysql_sg_id.value]
  subnet_id = local.db_subnet_id
  user_data = file("mysql.sh")
  tags = merge(
    {
        Name = "MySQL"
    },
    var.common_tags
  )
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  zone_name = var.zone_name
  records = [
    {
        name = "MySQL"
        type = "A"
        ttl = 1
        records = [
            module.mysql_instance.private_ip
        ]
    }
  ]
}


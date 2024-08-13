module "vpn_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  ami = data.aws_ami.devops_ami.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
  # subnet_id = local.public_subnet_ids[0]  # public subnet of default vpc, subnet_id is optional if we don't give EC2 instance will be provisioned inside default subnet of default vpc. 
  # user_data = file("roboshop-ansible.sh") # For now we don't have user data
  tags = merge(
    {
        Name = "Roboshop-VPN"
    },
    var.common_tags
  )
}
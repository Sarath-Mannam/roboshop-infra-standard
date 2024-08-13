data "aws_vpc" "default" {  # This Terraform configuration queries the default VPC data in the current region
  default = true
}

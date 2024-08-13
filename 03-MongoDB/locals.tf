locals {
  db_subnet_id = element(split(",", data.aws_ssm_parameter.database_subnet_ids.value),0)  # Here stringlist type of subnet id's in AWS Parameter store first spliting the subnet id based on comma (,) and selecting the value in 0 index 
}
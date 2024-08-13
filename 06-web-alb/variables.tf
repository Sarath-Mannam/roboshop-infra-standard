variable "project_name" {
  default = "roboshop"
}

variable "env" {
  default = "dev"
}

variable "common_tags" {
  default = {
    Project = "roboshop"
    Component = "Web-alb"
    Environment = "DEV"
    Terraform = "true"
  }
}


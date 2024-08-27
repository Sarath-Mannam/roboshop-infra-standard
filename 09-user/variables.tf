variable "project_name" {
  default = "roboshop"
}

variable "env" {
  default = "dev"
}

variable "common_tags" {
  default = {
    Project = "roboshop"
    Component = "user"
    Environment = "DEV"
    Terraform = "true"
  }
}

# variable "health_check" {
#   default = {
#     enabled = true
#     healthy_threshold = 2 # Continuously two health checks are success then you can consider as healthy
#     interval = 15 # For every 15 seconds will check health of the component
#     matcher = "200-299" # Any response code within this range consider it as success
#     path = "/" # will get the response if component is healthy
#     port = 80
#     protocol = "HTTP"
#     timeout = 5 # if there is no response within 5 seconds then consider it as failure
#     unhealthy_threshold = 3 # If three consecutive requests are failed then consider as failure
#   }
# }

variable "target_group_port" {
  default = 8080
}

variable "launch_template_tags" {
  default = [
    {
        resource_type = "instance"

        tags = {
        Name = "user"
        }
    },
    {
        resource_type = "volume"

        tags = {
        Name = "user"
        }
    }
  ]
}

variable "autoscaling_tags" {
    default = [
        {
         key                 = "Name"
         value               = "user"
         propagate_at_launch = true
        },
        {
         key                 = "Project"
         value               = "Roboshop"
         propagate_at_launch = true
        }
    ]
}
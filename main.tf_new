#---------My Project----------------------

provider "aws" {
    region     = "eu-west-1"
}
#-----------------------------------------
variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.micro"
}
#-----------------------------------------
variable "app_subnets" {
    type = list(string)
    description = "App subnets id"
    default = ["subnet-0012a2b95bca635c3", "subnet-043d42017aa4d466b"]
}
variable "vpc_id" {
    type = list(string)
    description = "App vpc id"
    default = ["vpc-0d3c54171c4b09049"]
}
#------------------------------------------------
data "aws_availability_zones" "available" {}
#------------------------------------------------
data "aws_instances" "webserver_instance" {
  instance_tags = {
    Name = "WebServer"
  }

  filter {
    name   = "tag:Name"
    values = ["WebServer"]
  }
  depends_on = [aws_autoscaling_group.webASG]
}

output "aws_instance_public_ip" {
    value = data.aws_instances.webserver_instance.public_ips
}
#--------------------------------------------------
data "aws_ami" "latest_ubuntu" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

#--------------------------------------------------------------
resource "aws_security_group" "webSG" {
  name = "Dynamic Security Group"

  dynamic "ingress" {
    for_each = ["80", "443", "22", "8080"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic SecurityGroup"
    Owner = "vzhyhalau"
  }
}
#----------------------------------------
resource "aws_launch_template" "web" {
  name = "web"
  image_id      = "ami-08edbb0e85d6a0a07"
  instance_type = "t3.micro"
  key_name = "TMS-ireland"
  user_data = filebase64("${path.module}/user_data.sh")
  disable_api_termination = true
  ebs_optimized = true
    cpu_options {
    core_count       = 1
    threads_per_core = 2
  }
  credit_specification {
    cpu_credits = "standard"
  }
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 10
    }
  }
  placement {
    availability_zone = "eu-west-1"
  }
  instance_initiated_shutdown_behavior = "terminate"
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  vpc_security_group_ids = [aws_security_group.webSG.id]
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "MyWebServer"
    }
  }
}
#--------------------------------------
resource "aws_lb_target_group" "webtg" {
  name     = "tf-lb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = var.vpc_id
}
#--------------------------------------------
resource "aws_lb_listener" "webListener" {
  load_balancer_arn = aws_lb.weblb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtg.arn
  }
}
#-------------------------------------------------
resource "aws_autoscaling_group" "webASG" {
  name                 = "ASG-${aws_launch_template.web.name}"
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  health_check_grace_period = 900
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_subnet.az1.id, aws_subnet.az2.id]
  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }
  target_group_arns    = [aws_lb_target_group.webtg.arn]
  dynamic "tag" {
    for_each = {
      Name   = "WebServer"
      Owner  = "vzhyhalau"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  depends_on = [aws_lb.weblb]
  lifecycle {
    create_before_destroy = true
  }
}
#-------------------------------
resource "aws_lb" "weblb" {
  name               = "weblb"
  internal           = false
  load_balancer_type = "application"
  subnets            =  var.app_subnets
  security_groups    = [aws_security_group.webSG.id]
  tags = {
    Name = "WebServer-ALB"
  }
#   provisioner "local-exec" {
#     command = "echo $var1 >> dns.txt"
#     environment = {
#         var1 = aws_lb.weblb.dns_name
#       }
#     }
}
#------------------------------------------
# resource "aws_default_subnet" "default_az1" {
#   availability_zone = data.aws_availability_zones.available.names[0]
# }
#
# resource "aws_default_subnet" "default_az2" {
#   availability_zone = data.aws_availability_zones.available.names[1]
# }
#------------------------------------------

resource "aws_subnet" "az1" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "az2" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}


#--------------------------------------------------
data "aws_lb" "weblb" {
       depends_on = [aws_lb.weblb]
}
#--------------------------------------------------
resource "null_resource" "exp_dns_name" {
  triggers = {
    dns_name         = aws_lb.weblb.dns_name
  }
  provisioner "local-exec" {
    command = "echo $var1 > dns.txt"
    environment = {
        var1 = aws_lb.weblb.dns_name
      }
    }
   depends_on = [aws_lb.weblb]
 }

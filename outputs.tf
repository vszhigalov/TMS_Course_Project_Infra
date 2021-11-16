# output "ami-ouput" {
#     description = "My ami output"
#     value = aws_instance.myWebServer.id
# }

# output "instance_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_elb.web.instances
# }
output "web_loadbalancer_url" {
  value = aws_lb.weblb.dns_name
}

output "latest_ubuntu_ami_id" {
  value = data.aws_ami.latest_ubuntu.id
}

output "latest_ubuntu_ami_name" {
  value = data.aws_ami.latest_ubuntu.name
}

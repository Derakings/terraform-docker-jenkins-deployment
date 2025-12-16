output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.docker_app.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.docker_app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.docker_app.public_dns
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.docker_app.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.docker_app_sg.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_instance.docker_app.public_ip}"
}

output "app_url" {
  description = "URL to access the Docker application"
  value       = "http://${aws_instance.docker_app.public_ip}${var.docker_port == 80 ? "" : ":${var.docker_port}"}"
}
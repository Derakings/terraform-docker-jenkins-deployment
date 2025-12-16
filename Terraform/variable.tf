variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  # No default - must be specified in terraform.tfvars
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (Ubuntu 22.04 LTS for your region)"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair (must exist in AWS)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the instance (your IP/32)"
  type        = list(string)
}


variable "environment" {
  description = "Environment name (development/staging/production)"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "docker-app-server"
}

variable "vpc_id" {
  description = "VPC ID (leave empty to use default VPC)"
  type        = string
  default     = ""
}

variable "docker_port" {
  description = "Port for Docker application (mapped from container port 5000)"
  type        = number
  default     = 80
}
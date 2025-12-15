variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance (Ubuntu 22.04 LTS)"
  type        = string
  default     = "ami-0d64bb532e0502c46"  # Ubuntu 22.04 LTS in eu-west-1
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "stage-3" # Change this to your key pair name
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

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH into the instance"
  type        = list(string)
  default     = ["3.252.125.223"]  # Change this to your IP for better security
}

variable "docker_port" {
  description = "Port for Docker application"
  type        = number
  default     = 5000
}
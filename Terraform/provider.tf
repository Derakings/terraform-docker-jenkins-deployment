terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # S3 backend for remote state storage
  backend "s3" {
    bucket         = "terraform-state-bucket-docker-app"  # Change this to your bucket name
    key            = "docker-app/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # Optional: for state locking
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "Docker-App"
      ManagedBy   = "Terraform"
    }
  }
}
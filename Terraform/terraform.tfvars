# AWS Configuration
aws_region  = "eu-west-1"
environment = "production"

instance_type = "t2.micro"
ami_id        = "ami-0d64bb532e0502c46"  # Ubuntu 22.04 LTS in eu-west-1
key_name      = "jenkins"  

instance_name = "docker-app-server"
vpc_id        = ""  

# Security Settings
allowed_ssh_cidr = ["34.245.151.138/32"]  
docker_port      = 80  # Map container port 5000 to host port 80
#!/bin/bash

# Jenkins Setup Script
# This script helps set up Jenkins with required plugins and configurations

set -e

echo "================================================"
echo "Jenkins Setup for Docker EC2 Deployment Pipeline"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This script will guide you through Jenkins setup${NC}\n"

# Check if Jenkins is installed
if ! command -v jenkins &> /dev/null; then
    echo -e "${RED}Error: Jenkins is not installed${NC}"
    echo "Please install Jenkins first:"
    echo "  Ubuntu/Debian: https://www.jenkins.io/doc/book/installing/linux/"
    echo "  macOS: brew install jenkins-lts"
    exit 1
fi

echo -e "${GREEN}✓ Jenkins is installed${NC}\n"

# Jenkins plugins to install
PLUGINS=(
    "workflow-aggregator"
    "git"
    "ssh-agent"
    "credentials-binding"
    "aws-credentials"
    "pipeline-stage-view"
)

echo "Required Jenkins Plugins:"
echo "========================"
for plugin in "${PLUGINS[@]}"; do
    echo "  - $plugin"
done

echo -e "\n${YELLOW}Install these plugins manually:${NC}"
echo "1. Go to Jenkins Dashboard"
echo "2. Navigate to: Manage Jenkins → Plugins → Available plugins"
echo "3. Search and install each plugin listed above"
echo "4. Restart Jenkins after installation"

echo -e "\n${YELLOW}Press Enter when plugins are installed...${NC}"
read

# Collect AWS credentials
echo -e "\n${GREEN}Step 1: AWS Credentials Configuration${NC}"
echo "======================================="
echo "You'll need:"
echo "  - AWS Access Key ID"
echo "  - AWS Secret Access Key"
echo "  - AWS Region (e.g., us-east-1)"
echo ""
echo "Add these to Jenkins:"
echo "  Dashboard → Manage Jenkins → Credentials → System → Global credentials"
echo "  → Add Credentials → AWS Credentials"
echo "  Credential ID: aws-credentials"

echo -e "\n${YELLOW}Press Enter when AWS credentials are added...${NC}"
read

# Collect SSH key info
echo -e "\n${GREEN}Step 2: SSH Key Configuration${NC}"
echo "=============================="
echo "You'll need:"
echo "  - EC2 SSH private key (.pem file)"
echo ""
read -p "Enter the path to your EC2 .pem key file: " PEM_PATH

if [ ! -f "$PEM_PATH" ]; then
    echo -e "${RED}Error: File not found: $PEM_PATH${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ SSH key file found${NC}"
echo ""
echo "Add this key to Jenkins:"
echo "  Dashboard → Manage Jenkins → Credentials → System → Global credentials"
echo "  → Add Credentials → SSH Username with private key"
echo "  - ID: ec2-ssh-key"
echo "  - Username: ubuntu"
echo "  - Private Key: Enter directly (paste content below)"
echo ""
echo "Content of your private key:"
echo "----------------------------"
cat "$PEM_PATH"
echo "----------------------------"

echo -e "\n${YELLOW}Press Enter when SSH key is added to Jenkins...${NC}"
read

# S3 Bucket setup
echo -e "\n${GREEN}Step 3: S3 Bucket for Terraform State${NC}"
echo "======================================"
read -p "Enter your S3 bucket name for Terraform state: " S3_BUCKET
read -p "Enter your AWS region (e.g., us-east-1): " AWS_REGION

echo -e "\n${YELLOW}Creating S3 bucket if it doesn't exist...${NC}"

if aws s3 ls "s3://$S3_BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket..."
    aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$S3_BUCKET" \
        --versioning-configuration Status=Enabled
    
    echo -e "${GREEN}✓ S3 bucket created with versioning enabled${NC}"
else
    echo -e "${GREEN}✓ S3 bucket already exists${NC}"
fi

# EC2 Key Pair
echo -e "\n${GREEN}Step 4: EC2 Key Pair${NC}"
echo "===================="
read -p "Enter your EC2 key pair name (or create new): " KEY_NAME

# Create terraform.tfvars
echo -e "\n${YELLOW}Creating terraform.tfvars file...${NC}"
cat > ../Terraform/terraform.tfvars <<EOF
aws_region     = "$AWS_REGION"
key_name       = "$KEY_NAME"
s3_bucket_name = "$S3_BUCKET"
s3_key         = "terraform/docker-app/terraform.tfstate"
instance_type  = "t2.micro"

allowed_ssh_cidr = ["0.0.0.0/0"]  # WARNING: Open to all, restrict in production!
allowed_http_cidr = ["0.0.0.0/0"]

common_tags = {
  Project     = "Docker-EC2-Deployment"
  Environment = "Development"
  ManagedBy   = "Terraform"
  CreatedBy   = "Jenkins"
}
EOF

echo -e "${GREEN}✓ terraform.tfvars created${NC}"

# Create Jenkins job
echo -e "\n${GREEN}Step 5: Create Jenkins Pipeline Job${NC}"
echo "===================================="
echo "Create a new pipeline job in Jenkins:"
echo "1. Go to Jenkins Dashboard"
echo "2. Click 'New Item'"
echo "3. Enter name: docker-ec2-deployment"
echo "4. Select: Pipeline"
echo "5. Click OK"
echo ""
echo "Configure the pipeline:"
echo "  - Definition: Pipeline script from SCM"
echo "  - SCM: Git"
echo "  - Repository URL: [Your Git repo URL]"
echo "  - Branch: */main"
echo "  - Script Path: Jenkinsfile"
echo ""

echo -e "\n${YELLOW}Press Enter when Jenkins job is created...${NC}"
read

# Summary
echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Setup Complete! 🎉${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Configuration Summary:"
echo "----------------------"
echo "  AWS Region: $AWS_REGION"
echo "  S3 Bucket: $S3_BUCKET"
echo "  EC2 Key Pair: $KEY_NAME"
echo "  Jenkins Credentials:"
echo "    - aws-credentials (AWS)"
echo "    - ec2-ssh-key (SSH)"
echo ""
echo "Next Steps:"
echo "----------"
echo "1. Push your code to Git repository"
echo "2. Update Jenkinsfile with your Git repo URL"
echo "3. Run the Jenkins pipeline: 'docker-ec2-deployment'"
echo "4. Monitor the build in Jenkins Console Output"
echo ""
echo -e "${YELLOW}Important Files Created:${NC}"
echo "  - Terraform/terraform.tfvars"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "  - Add terraform.tfvars to .gitignore (already done)"
echo "  - Never commit AWS credentials or SSH keys"
echo "  - Destroy resources when not in use to avoid AWS charges"
echo ""
echo "To destroy resources later:"
echo "  cd Terraform && terraform destroy -auto-approve"
echo ""
echo -e "${GREEN}Good luck with your deployment! 🚀${NC}"

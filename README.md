# Docker EC2 Deployment Project

Complete CI/CD pipeline using Jenkins to deploy a Dockerized Flask microservice on AWS EC2 with Terraform and S3 backend.

## 📋 Project Overview

This project automates the deployment of a Python Flask REST API microservice to AWS EC2 using:
- **Terraform** for infrastructure provisioning
- **Docker** for application containerization
- **Jenkins** for CI/CD automation
- **AWS S3** for Terraform state management

## 🏗️ Architecture

```
Jenkins Pipeline
    ↓
1. Clone Git Repository
    ↓
2. Install Terraform on Jenkins
    ↓
3. Provision EC2 (Terraform + S3 Backend)
    ↓
4. SSH into EC2
    ↓
5. Install Docker on EC2
    ↓
6. Copy Dockerfile & Build on EC2
    ↓
7. Run Docker Container
    ↓
Application Running on EC2:80 → Container:5000
```

## 📁 Project Structure

```
Docker-app/
├── app.py                  # Flask microservice application
├── requirements.txt        # Python dependencies
├── Dockerfile             # Docker container configuration
├── Jenkinsfile            # CI/CD pipeline definition
├── .dockerignore          # Docker build exclusions
├── .gitignore             # Git exclusions
├── README.md              # Project documentation
├── DEPLOYMENT.md          # Deployment guide
├── Terraform/
│   ├── main.tf            # EC2, Security Group, Key Pair
│   ├── provider.tf        # AWS provider + S3 backend
│   ├── variables.tf       # Input variables
│   ├── outputs.tf         # Output values (IP, DNS)
│   └── terraform.tfvars   # Variable values (git-ignored)
└── scripts/
    ├── setup-jenkins.sh   # Jenkins setup helper
    └── deploy-local.sh    # Local deployment script
```

## 🚀 Quick Start

### Prerequisites

1. **AWS Account** with:
   - IAM user with EC2, S3, VPC permissions
   - Access Key ID and Secret Access Key
   - S3 bucket for Terraform state
   - EC2 Key Pair (.pem file)

2. **Jenkins Server** with plugins:
   - Pipeline
   - Git
   - SSH Agent
   - AWS Credentials
   - Credentials Binding

3. **Git Repository** (GitHub, GitLab, Bitbucket)

### Step-by-Step Setup

#### 1. Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

#### 2. Create terraform.tfvars

Create `Terraform/terraform.tfvars`:

```hcl
aws_region     = "us-east-1"
key_name       = "your-ec2-keypair-name"
s3_bucket_name = "your-terraform-state-bucket"
s3_key         = "terraform/docker-app/terraform.tfstate"
instance_type  = "t2.micro"

allowed_ssh_cidr  = ["0.0.0.0/0"]
allowed_http_cidr = ["0.0.0.0/0"]

common_tags = {
  Project     = "Docker-EC2-Deployment"
  Environment = "Development"
  ManagedBy   = "Terraform"
  CreatedBy   = "Jenkins"
}
```

#### 3. Configure Jenkins Credentials

**AWS Credentials:**
1. Jenkins Dashboard → Manage Jenkins → Credentials
2. Add Credentials → AWS Credentials
3. ID: `aws-credentials`
4. Add your AWS Access Key and Secret Key

**SSH Key:**
1. Add Credentials → SSH Username with private key
2. ID: `ec2-ssh-key`
3. Username: `ubuntu`
4. Private Key: Paste your .pem file content

#### 4. Create Jenkins Pipeline

1. New Item → Pipeline → Name: `docker-ec2-deployment`
2. Pipeline section:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: Your Git repo URL
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
3. Save

#### 5. Run the Pipeline

Click **Build Now** in Jenkins

## 📖 Pipeline Stages Explained

### Stage 1: Clone Repository
Checks out code from your Git repository using Jenkins SCM plugin.

### Stage 2: Install Terraform
Downloads and installs Terraform 1.6.6 on the Jenkins agent if not already present.

### Stage 3: Create EC2 with Terraform
- Initializes Terraform with S3 backend
- Plans infrastructure changes
- Applies configuration to create:
  - EC2 instance
  - Security group (SSH, HTTP)
  - Outputs EC2 public IP

### Stage 4: SSH into Server
Tests SSH connectivity to the newly created EC2 instance.

### Stage 5: Install Docker on Server
- Updates system packages
- Installs Docker CE and dependencies
- Configures Docker service
- Adds ubuntu user to docker group

### Stage 6: Build Docker Image on Server
- Copies Dockerfile, app.py, requirements.txt to EC2
- Builds Docker image on the server
- Runs container on port 80 (maps to app port 5000)
- Configures auto-restart policy

### Stage 7: Verify Deployment
- Tests `/health` endpoint
- Tests `/api/users` endpoint
- Confirms application is responding

## 🔧 Application API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Service information |
| GET | `/health` | Health check |
| GET | `/api/users` | List all users |
| GET | `/api/users/:id` | Get specific user |
| POST | `/api/users` | Create new user |

### Example API Calls

```bash
# Get service info
curl http://YOUR_EC2_IP/

# Health check
curl http://YOUR_EC2_IP/health

# Get all users
curl http://YOUR_EC2_IP/api/users

# Get specific user
curl http://YOUR_EC2_IP/api/users/1

# Create new user
curl -X POST http://YOUR_EC2_IP/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

## 🛠️ Local Development

### Run Application Locally

```bash
# Install dependencies
pip install -r requirements.txt

# Run application
python app.py

# Access at http://localhost:5000
```

### Build and Run with Docker

```bash
# Build image
docker build -t user-microservice:latest .

# Run container
docker run -d -p 5000:5000 --name user-service user-microservice:latest

# Test
curl http://localhost:5000/health
```

### Test Terraform Configuration

```bash
cd Terraform

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy
terraform destroy
```

## 🔒 Security Considerations

### Production Recommendations

1. **Restrict SSH Access:**
   ```hcl
   allowed_ssh_cidr = ["YOUR_JENKINS_IP/32"]
   ```

2. **Enable HTTPS:**
   - Add SSL certificate
   - Configure NGINX/ALB
   - Redirect HTTP to HTTPS

3. **Use Secrets Manager:**
   - Store credentials in AWS Secrets Manager
   - Use IAM roles instead of access keys

4. **Enable Terraform State Locking:**
   - Add DynamoDB table for state locking
   - Prevent concurrent modifications

5. **Implement Monitoring:**
   - CloudWatch logs and metrics
   - Application performance monitoring (APM)
   - Security scanning

6. **Network Security:**
   - Use private subnets
   - NAT Gateway for outbound traffic
   - VPN or Direct Connect for access

## 💰 Cost Estimation

AWS resources created:
- **EC2 t2.micro**: $0.0116/hour (~$8.50/month) - Free Tier eligible
- **EBS Volume (8GB)**: $0.80/month
- **Elastic IP**: Free when attached
- **S3 Storage**: ~$0.023/GB/month (minimal)
- **Data Transfer**: First 1GB free

**Estimated monthly cost:** ~$10-15 (Free Tier: ~$0)

💡 **Tip:** Destroy resources when not in use!

## 🐛 Troubleshooting

### Issue: Terraform State Lock

```bash
# List S3 state files
aws s3 ls s3://your-bucket/terraform/docker-app/

# Force unlock if needed
cd Terraform
terraform force-unlock <LOCK_ID>
```

### Issue: SSH Connection Timeout

- Check security group allows port 22
- Verify key pair matches
- Increase wait time in stage 4
- Check EC2 instance status in AWS Console

### Issue: Docker Not Installed

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@EC2_IP

# Check Docker
sudo systemctl status docker

# Install manually if needed
sudo apt-get update
sudo apt-get install -y docker-ce
```

### Issue: Container Not Starting

```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@EC2_IP

# Check container logs
sudo docker logs user-microservice

# Check container status
sudo docker ps -a

# Restart container
sudo docker restart user-microservice
```

### Issue: Application Not Responding

```bash
# Check if container is running
sudo docker ps | grep user-microservice

# Check container logs
sudo docker logs user-microservice

# Test locally on EC2
curl http://localhost:5000/health

# Check security group allows port 80
```

## 📊 Monitoring and Logs

### View Application Logs

```bash
ssh -i your-key.pem ubuntu@EC2_IP
sudo docker logs -f user-microservice
```

### Check EC2 Metrics

- AWS Console → EC2 → Instances → Monitoring tab
- CloudWatch → Metrics → EC2

### Check Terraform State

```bash
cd Terraform
terraform show
terraform state list
```

## 🔄 Update Deployment

To deploy code changes:

1. Push changes to Git repository
2. Run Jenkins pipeline again
3. Pipeline will:
   - Skip EC2 creation (already exists)
   - Copy new files
   - Rebuild Docker image
   - Deploy updated container

## 🗑️ Cleanup Resources

### Via Terraform

```bash
cd Terraform
terraform destroy -auto-approve
```

### Manually via AWS Console

1. Terminate EC2 instance
2. Delete security group
3. Release Elastic IP (if attached)
4. Delete S3 bucket contents (optional)

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

MIT License - feel free to use this project for learning and development.

## 👨‍💻 Author

Created as a DevOps CI/CD pipeline demonstration project.

## 🎯 Next Steps

- [ ] Add automated tests (pytest)
- [ ] Implement blue-green deployment
- [ ] Add monitoring (Prometheus/Grafana)
- [ ] Set up log aggregation (ELK stack)
- [ ] Implement auto-scaling
- [ ] Add database (RDS/DynamoDB)
- [ ] Configure domain and SSL
- [ ] Set up backup strategy
- [ ] Implement secrets management
- [ ] Add CI/CD for infrastructure changes

---

**Need help?** Check the [DEPLOYMENT.md](DEPLOYMENT.md) file for detailed deployment instructions.

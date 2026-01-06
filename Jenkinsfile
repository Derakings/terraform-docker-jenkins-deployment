pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-west-1'
        TF_VERSION = '1.6.6'
        DOCKER_IMAGE_NAME = 'user-microservice'
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}"
        SSH_KEY_CREDENTIAL_ID = 'ec2-ssh-key'
        AWS_CREDENTIAL_ID = 'aws-credentials'
        
        // Terraform Variables
        TF_VAR_aws_region = 'eu-west-1'
        TF_VAR_ami_id = 'ami-0d64bb532e0502c46'
        TF_VAR_key_name = 'jenkins'

    }
    
    stages {
        // Step 1: Clone the repo
        stage('1. Clone Repository') {
            steps {
                echo '========================================'
                echo 'Step 1: Cloning the repository'
                echo '========================================'
                checkout scm
                echo '✓ Repository cloned successfully'
            }
        }
        
        // Step 2: Installing Terraform
        stage('2. Install Terraform') {
            steps {
                script {
                    echo '========================================'
                    echo 'Step 2: Installing Terraform'
                    echo '========================================'
                    sh """
                        # Set up local bin directory for Jenkins user
                        mkdir -p \$HOME/.local/bin
                        export PATH="\$HOME/.local/bin:\$PATH"
                        
                        # Check if Terraform is installed in user bin
                        if [ -f "\$HOME/.local/bin/terraform" ]; then
                            INSTALLED_VERSION=\$(\$HOME/.local/bin/terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
                            echo "Terraform \$INSTALLED_VERSION is already installed"
                            if [ "\$INSTALLED_VERSION" == "${TF_VERSION}" ]; then
                                echo "✓ Correct version already installed"
                                exit 0
                            fi
                        fi
                        
                        # Install Terraform to user directory (no sudo needed)
                        echo "Installing Terraform ${TF_VERSION}..."
                        cd /tmp
                        wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
                        unzip -o terraform_${TF_VERSION}_linux_amd64.zip
                        mv terraform \$HOME/.local/bin/
                        rm terraform_${TF_VERSION}_linux_amd64.zip
                        
                        # Verify installation
                        \$HOME/.local/bin/terraform version
                        echo "✓ Terraform installed successfully to \$HOME/.local/bin"
                    """
                }
            }
        }
        
        // Step 3: Creating the EC2 with the Terraform config
        stage('3. Create EC2 with Terraform') {
            steps {
                dir('Terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: "${AWS_CREDENTIAL_ID}",
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        script {
                            echo '========================================'
                            echo 'Step 3: Creating EC2 with Terraform'
                            echo '========================================'
                            
                            echo 'Initializing Terraform with S3 backend...'
                            sh '$HOME/.local/bin/terraform init'
                            
                            echo 'Planning infrastructure changes...'
                            sh '''
                                $HOME/.local/bin/terraform plan \
                                    -var="allowed_ssh_cidr=[\\"3.252.125.223/32\\"]" \
                                    -out=tfplan
                            '''
                            
                            echo 'Applying Terraform configuration...'
                            sh '$HOME/.local/bin/terraform apply -auto-approve tfplan'
                            
                            // Capture EC2 public IP
                            env.EC2_PUBLIC_IP = sh(
                                script: '$HOME/.local/bin/terraform output -raw instance_public_ip',
                                returnStdout: true
                            ).trim()
                            
                            echo "✓ EC2 Instance created successfully"
                            echo "EC2 Public IP: ${env.EC2_PUBLIC_IP}"
                            
                            // Wait for EC2 to initialize
                            echo 'Waiting 60 seconds for EC2 to fully initialize...'
                            sleep(60)
                        }
                    }
                }
            }
        }
        
        // Step 4: SSH into the server
        stage('4. SSH into Server') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: "${SSH_KEY_CREDENTIAL_ID}",
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )]) {
                        echo '========================================'
                        echo 'Step 4: Testing SSH connection to server'
                        echo '========================================'
                        
                        sh """
                            # Test SSH connection
                            ssh -o StrictHostKeyChecking=no -i \${SSH_KEY} ubuntu@${env.EC2_PUBLIC_IP} '
                                echo "✓ SSH connection successful!"
                                echo "Hostname: \$(hostname)"
                                echo "OS: \$(lsb_release -d | cut -f2)"
                                echo "User: \$(whoami)"
                            '
                        """
                    }
                }
            }
        }
        
        // Step 5: Install Docker in the server
        stage('5. Install Docker on Server') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: "${SSH_KEY_CREDENTIAL_ID}",
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )]) {
                        echo '========================================'
                        echo 'Step 5: Installing Docker on server'
                        echo '========================================'
                        
                        sh """
                            ssh -o StrictHostKeyChecking=no -i \${SSH_KEY} ubuntu@${env.EC2_PUBLIC_IP} '
                                # Update system
                                echo "Updating system packages..."
                                sudo apt-get update -y
                                
                                # Check if Docker is already installed
                                if command -v docker &> /dev/null; then
                                    echo "Docker is already installed"
                                    docker --version
                                    exit 0
                                fi
                                
                                echo "Installing Docker..."
                                
                                # Install Docker dependencies
                                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                                
                                # Add Docker GPG key
                                sudo mkdir -p /etc/apt/keyrings
                                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                                
                                # Add Docker repository
                                echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                                
                                # Install Docker
                                sudo apt-get update -y
                                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
                                
                                # Start Docker
                                sudo systemctl start docker
                                sudo systemctl enable docker
                                
                                # Add ubuntu user to docker group
                                sudo usermod -aG docker ubuntu
                                
                                echo "✓ Docker installed successfully"
                                sudo docker --version
                            '
                        """
                    }
                }
            }
        }
        
        // Step 6: Copy Dockerfile and build on server
        stage('6. Build Docker Image on Server') {
            steps {
                script {
                    withCredentials([sshUserPrivateKey(
                        credentialsId: "${SSH_KEY_CREDENTIAL_ID}",
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )]) {
                        echo '========================================'
                        echo 'Step 6: Copying files and building Docker image'
                        echo '========================================'
                        
                        // Create app directory on EC2
                        sh """
                            ssh -o StrictHostKeyChecking=no -i \${SSH_KEY} ubuntu@${env.EC2_PUBLIC_IP} 'mkdir -p /home/ubuntu/app'
                        """
                        
                        // Copy application files to EC2
                        echo 'Copying Dockerfile and application files...'
                        sh """
                            scp -o StrictHostKeyChecking=no -i \${SSH_KEY} Dockerfile ubuntu@${env.EC2_PUBLIC_IP}:/home/ubuntu/app/
                            scp -o StrictHostKeyChecking=no -i \${SSH_KEY} app.py ubuntu@${env.EC2_PUBLIC_IP}:/home/ubuntu/app/
                            scp -o StrictHostKeyChecking=no -i \${SSH_KEY} requirements.txt ubuntu@${env.EC2_PUBLIC_IP}:/home/ubuntu/app/
                        """
                        
                        // Build Docker image on EC2
                        echo 'Building Docker image on server...'
                        sh """
                            ssh -o StrictHostKeyChecking=no -i \${SSH_KEY} ubuntu@${env.EC2_PUBLIC_IP} '
                                cd /home/ubuntu/app
                                
                                # Stop and remove old container if exists
                                sudo docker stop ${DOCKER_IMAGE_NAME} 2>/dev/null || true
                                sudo docker rm ${DOCKER_IMAGE_NAME} 2>/dev/null || true
                                
                                # Build Docker image
                                echo "Building Docker image..."
                                sudo docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                                sudo docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
                                
                                # Run Docker container
                                echo "Starting Docker container..."
                                sudo docker run -d \
                                    --name ${DOCKER_IMAGE_NAME} \
                                    -p 80:5000 \
                                    --restart unless-stopped \
                                    ${DOCKER_IMAGE_NAME}:latest
                                
                                # Wait for container to start
                                sleep 5
                                
                                # Check container status
                                sudo docker ps | grep ${DOCKER_IMAGE_NAME}
                                
                                echo "✓ Container deployed successfully!"
                            '
                        """
                    }
                }
            }
        }
        
        // Step 7: Verify deployment (Bonus step)
        stage('7. Verify Deployment') {
            steps {
                script {
                    echo '========================================'
                    echo 'Step 7: Verifying application deployment'
                    echo '========================================'
                    
                    sh """
                        # Wait for application to be ready
                        sleep 10
                        
                        # Test health endpoint
                        echo "Testing health endpoint..."
                        curl -f http://${env.EC2_PUBLIC_IP}/health || exit 1
                        
                        # Test API endpoint
                        echo "Testing API endpoint..."
                        curl -f http://${env.EC2_PUBLIC_IP}/api/users || exit 1
                        
                        echo "✓ Application is responding correctly!"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '''
            ========================================
            ✓ DEPLOYMENT SUCCESSFUL!
            ========================================
            All steps completed successfully:
            ✓ Step 1: Repository cloned
            ✓ Step 2: Terraform installed
            ✓ Step 3: EC2 instance created
            ✓ Step 4: SSH connection established
            ✓ Step 5: Docker installed on server
            ✓ Step 6: Docker image built and deployed
            ✓ Step 7: Application verified (S3 state used)
            ========================================
            '''
            
            echo """
            Application Details:
            - URL: http://${env.EC2_PUBLIC_IP}
            - Health: http://${env.EC2_PUBLIC_IP}/health
            - API: http://${env.EC2_PUBLIC_IP}/api/users
            - SSH: ssh -i <your-key.pem> ubuntu@${env.EC2_PUBLIC_IP}
            
            Terraform State: Stored in S3 bucket
            ========================================
            """
        }
        
        failure {
            echo 'Pipeline failed! Check the console output for details.'
        }
        
        always {
            cleanWs()
        }
    }
}
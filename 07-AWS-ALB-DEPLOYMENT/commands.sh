#!/bin/bash

# ==========================================

# Terraform Lab 01

# AWS ALB Deployment

# ==========================================

# Install AWS CLI

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

sudo ./aws/install

# Verify AWS CLI

aws --version

# Configure AWS Credentials

aws configure

# Install Terraform

sudo apt update

sudo apt install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | 
gpg --dearmor | 
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] 
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | 
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt install terraform

# Verify Terraform

terraform version

# Configure Git

git config --global user.name "shaurya-sehgal5"

git config --global user.email "[shauryasehgal555@gmail.com](mailto:shauryasehgal555@gmail.com)"

# Initialize Terraform

terraform init

# Validate Configuration

terraform validate

# Preview Infrastructure

terraform plan

# Create Infrastructure

terraform apply

# View Outputs

terraform output

# Destroy Infrastructure

terraform destroy


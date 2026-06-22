#!/bin/bash

# ==========================================

# Kubernetes Lab 01

# EKS + ALB Ingress Controller

# ==========================================

# Verify AWS CLI

aws sts get-caller-identity

# Verify kubectl

kubectl version --client

# Verify eksctl

eksctl version

# Create EKS Cluster

eksctl create cluster 
--name my-fargate-cluster 
--region ap-south-1 
--nodes 2 
--node-type t3.medium 
--fargate

# Update kubeconfig

aws eks update-kubeconfig 
--region ap-south-1 
--name my-fargate-cluster

# Verify Cluster Access

kubectl get nodes

# Deploy Sample Application

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/examples/2048/2048_full.yaml

# Verify Resources

kubectl get pods -A

kubectl get svc -A

kubectl get ingress -A

# Associate IAM OIDC Provider

eksctl utils associate-iam-oidc-provider 
--cluster my-fargate-cluster 
--region ap-south-1 
--approve

# Download IAM Policy

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.11.0/docs/install/iam_policy.json

# Create IAM Policy

aws iam create-policy 
--policy-name AWSLoadBalancerControllerIAMPolicy 
--policy-document file://iam_policy.json

# Create IAM Service Account

eksctl create iamserviceaccount 
--cluster=my-fargate-cluster 
--region=ap-south-1 
--namespace=kube-system 
--name=aws-load-balancer-controller 
--role-name AmazonEKSLoadBalancerControllerRole 
--attach-policy-arn=arn:aws:iam::114403655679:policy/AWSLoadBalancerControllerIAMPolicy 
--approve

# Install Helm

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add EKS Helm Repository

helm repo add eks https://aws.github.io/eks-charts

helm repo update

# Install AWS Load Balancer Controller

helm install aws-load-balancer-controller eks/aws-load-balancer-controller 
-n kube-system 
--set clusterName=my-fargate-cluster 
--set serviceAccount.create=false 
--set serviceAccount.name=aws-load-balancer-controller 
--set region=ap-south-1 
--set vpcId=vpc-055f3e1b7d90aeeb

# Verify Controller

kubectl get deployment 
-n kube-system 
aws-load-balancer-controller

# Verify Pods

kubectl get pods -n kube-system

# Verify Ingress

kubectl get ingress

# Verify ALB

kubectl describe ingress ingress-2048


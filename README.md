# Project Barakat 2025 Capstone - EKS Infrastructure

Production-grade Kubernetes infrastructure for the AWS Retail Store Sample App on Amazon EKS.

## Overview

This project deploys a complete microservices architecture on AWS EKS with:
- VPC with public and private subnets across 2 AZs
- EKS Cluster (v1.34) with managed node groups
- Retail Store Sample App with in-cluster dependencies
- CloudWatch observability (control plane + container logs)
- Event-driven Lambda processing for S3 uploads
- GitHub Actions CI/CD automation

## Prerequisites

- AWS Account with credentials configured
- Terraform 1.5+
- kubectl
- Helm 3
- Git

## Quick Start
```bash
# Clone the repository
git clone https://github.com/jacqueline-anyanwu/project-barakat-2025-capstone.git
cd project-barakat-2025-capstone

# Deploy infrastructure
terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --name project-bedrock-cluster --region us-east-1

# Deploy retail app
kubectl apply -f retail-app.yaml -n retail-app

# Wait for all pods
kubectl wait --for=condition=available deployments --all -n retail-app --timeout=5m

# Access the application
kubectl get svc ui -n retail-app
```
**Note:** The infrastructure and application are automatically deployed via GitHub Actions CI/CD pipeline on push to main branch. See CI/CD Pipeline section for details.

## Architecture

- **VPC**: project-bedrock-vpc (10.0.0.0/16)
- **EKS Cluster**: project-bedrock-cluster (Kubernetes v1.34)
- **Worker Nodes**: 2x t3.small (with auto-scaling up to 3)
- **Namespaces**: retail-app, amazon-cloudwatch, kube-system
- **Storage**: bedrock-assets-1115 (S3 bucket)
- **Processing**: bedrock-asset-processor (Lambda)

## Features

- ✅ Infrastructure as Code (Terraform)
- ✅ Remote state management (S3 + DynamoDB)
- ✅ Secure developer access (IAM + RBAC)
- ✅ Observability (CloudWatch Logs)
- ✅ Event-driven serverless (Lambda + S3)
- ✅ CI/CD automation (GitHub Actions)

## CI/CD Pipeline

The project includes automated GitHub Actions workflow that:

1. **On Pull Request**: Runs `terraform plan` to preview infrastructure changes
2. **On Merge to Main**: Executes:
   - `terraform apply` - Deploys/updates infrastructure
   - `kubectl apply` - Deploys the retail application

Workflow file: `.github/workflows/terraform.yaml`

AWS credentials are securely stored as GitHub repository secrets.

## Cleanup

To delete all resources and stop AWS charges:
```bash
terraform destroy -auto-approve
```

## License

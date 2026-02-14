# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  map_public_ip_on_launch = true

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project = "barakat-2025-capstone"
  }
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  eks_managed_node_groups = {
    general = {
      name           = "general-node-group"
      use_name_prefix = true
      capacity_type  = "ON_DEMAND"

      instance_types = [var.instance_type]

      desired_size = var.desired_size
      min_size     = var.min_size
      max_size     = var.max_size

      tags = {
        Project = "barakat-2025-capstone"
      }
    }
  }

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      most_recent       = true
    }
  }

  tags = {
    Project = "barakat-2025-capstone"
  }
}

# S3 Bucket for Assets
resource "aws_s3_bucket" "assets" {
  bucket = "bedrock-assets-1115"

  tags = {
    Project = "barakat-2025-capstone"
  }
}

# Enable versioning on S3 bucket
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add root user to cluster RBAC
resource "aws_eks_access_entry" "root" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  kubernetes_groups = []
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "root" {
  cluster_name       = module.eks.cluster_name
  policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  access_scope {
    type = "cluster"
  }
}

# IAM User for Developer Access
resource "aws_iam_user" "bedrock_dev_view" {
  name = "bedrock-dev-view"

  tags = {
    Project = "barakat-2025-capstone"
  }
}

# Attach ReadOnlyAccess policy for AWS Console
resource "aws_iam_user_policy_attachment" "bedrock_dev_readonly" {
  user       = aws_iam_user.bedrock_dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Create custom policy for S3 PutObject
resource "aws_iam_user_policy" "bedrock_dev_s3_put" {
  name   = "bedrock-dev-s3-put"
  user   = aws_iam_user.bedrock_dev_view.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

# Generate Access Keys for the developer user
resource "aws_iam_access_key" "bedrock_dev_key" {
  user = aws_iam_user.bedrock_dev_view.name
}

# Map IAM user to Kubernetes RBAC view role
resource "aws_eks_access_entry" "bedrock_dev" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_user.bedrock_dev_view.arn
  kubernetes_groups = []
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "bedrock_dev_view" {
  cluster_name       = module.eks.cluster_name
  policy_arn         = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  principal_arn      = aws_iam_user.bedrock_dev_view.arn
  access_scope {
    type = "cluster"
  }
}
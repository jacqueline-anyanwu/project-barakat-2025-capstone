output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "assets_bucket_name" {
  description = "S3 assets bucket name"
  value       = aws_s3_bucket.assets.id
}

output "bedrock_dev_access_key_id" {
  description = "Access Key ID for bedrock-dev-view user"
  value       = aws_iam_access_key.bedrock_dev_key.id
}

output "bedrock_dev_secret_access_key" {
  description = "Secret Access Key for bedrock-dev-view user"
  value       = aws_iam_access_key.bedrock_dev_key.secret
  sensitive   = true
}
terraform {
  backend "s3" {
    bucket         = "bedrock-tfstate-barakat-2025"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "bedrock-tfstate-lock"
  }
}
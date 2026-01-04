provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CSV-Data-Pipeline"
      Environment = "Production"
      ManagedBy   = "Terraform"
      Owner       = "ShenLoong"
    }
  }
}

# Add this block to fetch your AWS Account ID dynamically
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

resource "random_id" "suffix" {
  byte_length = 4
}
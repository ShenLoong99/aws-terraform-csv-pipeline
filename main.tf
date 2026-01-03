provider "aws" {
  region = var.aws_region
}

# Add this block to fetch your AWS Account ID dynamically
data "aws_caller_identity" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}
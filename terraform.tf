terraform {
  required_version = ">= 1.5"

  #   backend "remote" {
  #     hostname     = "app.terraform.io"
  #     organization = "my-terraform-aws-projects-2025"

  #     workspaces {
  #       name = "bucket-list-tracker"
  #     }
  #   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

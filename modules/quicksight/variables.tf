variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "default_tags" {
  description = "Extra tags to pass to the provider"
  type        = map(string)
}

variable "email" {
  description = "Email address for QuickSight notifications"
  type        = string
}

variable "transformed_bucket_id" {
  description = "ID of S3 transformed bucket"
  type        = string
}

variable "manifest_key" {
  description = "The key (path) of the manifest file if it was uploaded"
  type        = string
}

variable "transformed_bucket_arn" {
  description = "ARN of S3 transformed bucket"
  type        = string
}

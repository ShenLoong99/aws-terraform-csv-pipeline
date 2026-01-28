variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "default_tags" {
  description = "Extra tags to pass to the provider"
  type        = map(string)
}

variable "processed_bucket_id" {
  description = "ID of S3 processed bucket"
  type        = string
}

variable "processed_bucket_arn" {
  description = "ARN of S3 processed bucket"
  type        = string
}

variable "raw_bucket_arn" {
  description = "ARN of S3 raw bucket"
  type        = string
}

variable "raw_bucket_id" {
  description = "ID of S3 raw bucket"
  type        = string
}

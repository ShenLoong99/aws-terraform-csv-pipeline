variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "default_tags" {
  description = "Extra tags to pass to the provider"
  type        = map(string)
}

variable "project_name" {
  description = "Prefix for project resources"
  type        = string
}

variable "bucket_type" {
  description = "Name for type of bucket"
  type        = string
}

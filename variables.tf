variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix for project resources"
  type        = string
  default     = "my-pipeline"
}

variable "email" {
  description = "Email address for QuickSight notifications"
  type        = string
}
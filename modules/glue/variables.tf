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

variable "transformed_bucket_id" {
  description = "ID of S3 transformed bucket"
  type        = string
}

variable "transformed_bucket_arn" {
  description = "ARN of S3 transformed bucket"
  type        = string
}

variable "scripts_bucket_id" {
  description = "ID of S3 scripts bucket"
  type        = string
}

variable "scripts_bucket_arn" {
  description = "ARN of S3 scripts bucket"
  type        = string
}

variable "glue_script_key" {
  description = "The key (path) of the glue script if it was uploaded"
  type        = string
}

variable "lambda_exec_id" {
  description = "ID of the IAM lambda role exec"
  type        = string
}

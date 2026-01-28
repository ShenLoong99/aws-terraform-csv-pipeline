output "raw_bucket_id" {
  description = "Name of S3 bucket for storing raw data"
  value       = module.raw_storage.bucket_id
}

output "processed_bucket_id" {
  description = "Name of S3 bucket for storing processed data"
  value       = module.processed_storage.bucket_id
}

output "transformed_bucket_id" {
  description = "Name of S3 bucket for storing transformed data"
  value       = module.transformed_storage.bucket_id
}

output "lambda_function_name" {
  description = "The lambda function name"
  value       = module.lambda.lambda_function_name
}

output "aws_region" {
  description = "AWS Region to deploy resources"
  value       = var.aws_region
}

output "glue_job_name" {
  description = "Name of the glue job"
  value       = module.glue.glue_job_name
}

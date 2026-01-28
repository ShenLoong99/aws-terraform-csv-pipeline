output "bucket_id" {
  description = "Name of S3 bucket"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "ARN of S3 bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "manifest_key" {
  description = "The key (path) of the manifest file if it was uploaded"
  value       = aws_s3_object.manifest[*].key
}

output "upload_glue_script_key" {
  description = "The key (path) of the glue script if it was uploaded"
  value       = aws_s3_object.upload_glue_script[*].key
}

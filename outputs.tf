output "raw_bucket_name" {
  value = aws_s3_bucket.raw.id
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed.id
}

output "transformed_bucket_name" {
  value = aws_s3_bucket.transformed.id
}

output "lambda_function_name" {
  value = aws_lambda_function.csv_cleaner.function_name
}
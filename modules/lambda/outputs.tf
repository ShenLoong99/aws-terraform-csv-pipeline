output "lambda_function_name" {
  description = "The lambda function name"
  value       = aws_lambda_function.csv_cleaner.function_name
}

output "lambda_exec_id" {
  description = "ID of the IAM lambda role exec"
  value       = aws_iam_role.lambda_exec.id
}

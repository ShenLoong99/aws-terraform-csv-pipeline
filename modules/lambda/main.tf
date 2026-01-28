# Zip the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/cleaning_lambda.py"
  output_path = "${path.module}/lambda/lambda_function_payload.zip"
}

# This function triggers when a file hits the raw bucket.
resource "aws_lambda_function" "csv_cleaner" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "csv_data_cleaner"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "cleaning_lambda.handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      DEST_BUCKET = var.processed_bucket_id
    }
  }

  # Enable X-Ray Tracing for the Lambda function
  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

# S3 Trigger Permission
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_cleaner.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.raw_bucket_arn
}

resource "aws_s3_bucket_notification" "raw_upload_trigger" {
  bucket = var.raw_bucket_id
  lambda_function {
    lambda_function_arn = aws_lambda_function.csv_cleaner.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  # ensure the permission exists first
  depends_on = [aws_lambda_permission.allow_s3_to_call_lambda]
}

# Create the SQS Queue to act as the DLQ
resource "aws_sqs_queue" "lambda_dlq" {
  name                    = "csv-pipeline-lambda-dlq"
  sqs_managed_sse_enabled = true # Fixes CKV_AWS_27
}

# Grant Lambda permission to send to SQS
resource "aws_iam_role_policy" "lambda_sqs_dlq" {
  name = "lambda_sqs_dlq_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "sqs:SendMessage"
      Effect   = "Allow"
      Resource = aws_sqs_queue.lambda_dlq.arn
    }]
  })
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_exec" {
  name = "csv_pipeline_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Assign policy to lambda role for managing S3 buckets and Cloudwatch log groups
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${var.raw_bucket_arn}/*"
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${var.processed_bucket_arn}/*"
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.lambda_log_group.arn}:*"
      }
    ]
  })
}

# Assign permission to lambda for calling S3
resource "aws_lambda_permission" "allow_s3_to_call_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_cleaner.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.raw_bucket_arn
}

# Manage the Lambda Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.csv_cleaner.function_name}"
  retention_in_days = 7
}

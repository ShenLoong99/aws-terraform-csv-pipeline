// This function triggers when a file hits the raw bucket.
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
      DEST_BUCKET = aws_s3_bucket.processed.id
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }
}

# Zip the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/scripts/cleaning_lambda.py"
  output_path = "${path.module}/scripts/lambda_function_payload.zip"
}

# S3 Trigger Permission
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_cleaner.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw.arn
}

resource "aws_s3_bucket_notification" "raw_upload_trigger" {
  bucket = aws_s3_bucket.raw.id
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
  name = "csv-pipeline-lambda-dlq"
}

# Grant Lambda permission to send to SQS (Add to iam.tf)
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
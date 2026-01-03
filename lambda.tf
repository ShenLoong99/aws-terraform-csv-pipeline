// This function triggers when a file hits the raw bucket.
resource "aws_lambda_function" "csv_cleaner" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "csv_data_cleaner"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "cleaning_lambda.handler"
  runtime          = "python3.13"
  timeout          = 60
  memory_size      = 128

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.processed.id
    }
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
}
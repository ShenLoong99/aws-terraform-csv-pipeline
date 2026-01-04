# --- Lambda IAM Role ---
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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_s3_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject", "s3:DeleteObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.raw.arn}/*"
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.processed.arn}/*"
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.lambda_log_group.arn}:*"
      }
    ]
  })
}

# --- Glue IAM Role ---
resource "aws_iam_role" "glue_role" {
  name = "csv_pipeline_glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
    }]
  })
}

# Attach standard AWS Glue Service Policy
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Custom policy for Glue S3 access
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "glue_s3_data_access"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:PutObject"]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.processed.arn}/*",
          "${aws_s3_bucket.transformed.arn}/*",
          "${aws_s3_bucket.scripts.arn}/*"
        ]
      }
    ]
  })
}

# Policy to allow QuickSight to access the Transformed S3 bucket
resource "aws_iam_policy" "quicksight_s3_access" {
  name        = "QuickSightS3AccessPolicy"
  description = "Allows QuickSight to read data and manifest from S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetObject", "s3:GetObjectVersion", "s3:ListBucket"]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.transformed.arn,
          "${aws_s3_bucket.transformed.arn}/*"
        ]
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = [aws_s3_bucket.transformed.arn]
      }
    ]
  })
}

# Define the Custom QuickSight Service Role
resource "aws_iam_role" "quicksight_custom_role" {
  name = "CustomQuickSightS3AccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "quicksight.amazonaws.com"
      }
    }]
  })
}

# add a policy statement to grants the glue:StartJobRun permission.
resource "aws_iam_role_policy" "lambda_glue_trigger" {
  name = "lambda_glue_trigger_policy"
  role = aws_iam_role.lambda_exec.id # Ensure this matches your role name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "glue:StartJobRun"
        Effect   = "Allow"
        Resource = aws_glue_job.transform_job.arn
      }
    ]
  })
}

# Attach the policy to the standard QuickSight service role
resource "aws_iam_role_policy_attachment" "quicksight_s3_attach" {
  role       = aws_iam_role.quicksight_custom_role.name
  policy_arn = aws_iam_policy.quicksight_s3_access.arn
}

resource "aws_lambda_permission" "allow_s3_to_call_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.csv_cleaner.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw.arn
}

# Manage the Lambda Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.csv_cleaner.function_name}"
  retention_in_days = 7
}

# Manage the Glue Continuous Log Group
resource "aws_cloudwatch_log_group" "glue_log_group" {
  name              = "/aws-glue/jobs/csv-transform-job"
  retention_in_days = 7
}

# Manage the default Glue Output Log Groups (to ensure they are deleted)
resource "aws_cloudwatch_log_group" "glue_output_logs" {
  name              = "/aws-glue/jobs/output"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "glue_error_logs" {
  name              = "/aws-glue/jobs/error"
  retention_in_days = 7
}
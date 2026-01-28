# Glue resource
resource "aws_glue_catalog_database" "pipeline_db" {
  name = "csv_pipeline_db"
}

# Discovers the schema of the processed data
resource "aws_glue_crawler" "processed_crawler" {
  database_name          = aws_glue_catalog_database.pipeline_db.name
  name                   = "processed-data-crawler"
  role                   = aws_iam_role.glue_role.arn
  security_configuration = aws_glue_security_configuration.free_tier_config.name

  s3_target {
    path = "s3://${var.processed_bucket_id}/"
  }
}

# Reference that S3 location in the Glue Job
resource "aws_glue_job" "transform_job" {
  name                   = "csv-transform-job"
  role_arn               = aws_iam_role.glue_role.arn
  glue_version           = "4.0"  # Use modern Spark 3.3
  worker_type            = "G.1X" # Standard worker (4 vCPU, 16GB RAM)
  number_of_workers      = 2      # Smallest scale (2 workers)
  max_retries            = 0      # Do not retry on failure (saves cost)
  timeout                = 10     # Kill job if it runs longer than 10 mins
  security_configuration = aws_glue_security_configuration.free_tier_config.name

  command {
    # This URL points to the object we just uploaded
    script_location = "s3://${var.scripts_bucket_id}/${var.glue_script_key}"
    python_version  = "3"
  }

  default_arguments = {
    "--DATABASE" = aws_glue_catalog_database.pipeline_db.name
    # Dynamically calculate the table name based on the bucket name
    "--TABLE"                = replace(var.processed_bucket_id, "-", "_")
    "--OUTPUT_PATH"          = "s3://${var.transformed_bucket_id}/transformed-data/"
    "--DATABASE_BUCKET_NAME" = var.processed_bucket_id
    # Required for the script to handle standard Glue arguments
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = "/aws-glue/jobs/csv-transform-job"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}

# add a policy statement to grants the glue:StartJobRun permission.
resource "aws_iam_role_policy" "lambda_glue_trigger" {
  name = "lambda_glue_trigger_policy"
  role = var.lambda_exec_id

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

# Glue IAM Role
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
          "${var.processed_bucket_arn}/*",
          "${var.transformed_bucket_arn}/*",
          "${var.scripts_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_glue_security_configuration" "free_tier_config" {
  name = "glue-security-config"

  encryption_configuration {
    # CloudWatch Logs: Set to DISABLED to avoid KMS costs.
    # Standard CloudWatch encryption still applies at the service level.
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "DISABLED"
    }

    # Job Bookmarks: Set to DISABLED to avoid KMS costs.
    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "DISABLED"
    }

    # S3 Data: Use SSE-S3 (Free, managed by Amazon).
    s3_encryption {
      s3_encryption_mode = "SSE-S3"
    }
  }
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

# Manage the Glue Error Log Group
resource "aws_cloudwatch_log_group" "glue_error_logs" {
  name              = "/aws-glue/jobs/error"
  retention_in_days = 7
}

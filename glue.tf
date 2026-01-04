resource "aws_glue_catalog_database" "pipeline_db" {
  name = "csv_pipeline_db"
}

// discovers the schema of the processed data
resource "aws_glue_crawler" "processed_crawler" {
  database_name = aws_glue_catalog_database.pipeline_db.name
  name          = "processed-data-crawler"
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.processed.id}/"
  }
}

# Reference that S3 location in the Glue Job
resource "aws_glue_job" "transform_job" {
  name     = "csv-transform-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    # This URL points to the object we just uploaded
    script_location = "s3://${aws_s3_bucket.scripts.id}/${aws_s3_object.upload_glue_script.key}"
    python_version  = "3"
  }

  default_arguments = {
    "--DATABASE" = aws_glue_catalog_database.pipeline_db.name
    # Dynamically calculate the table name based on the bucket name
    "--TABLE"                = replace(aws_s3_bucket.processed.id, "-", "_")
    "--OUTPUT_PATH"          = "s3://${aws_s3_bucket.transformed.id}/transformed-data/"
    "--DATABASE_BUCKET_NAME" = aws_s3_bucket.processed.id
    # Required for the script to handle standard Glue arguments
    "--job-language"                     = "python"
    "--continuous-log-logGroup"          = "/aws-glue/jobs/csv-transform-job"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}
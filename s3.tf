resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed-${random_id.suffix.hex}"
}

resource "aws_s3_bucket" "transformed" {
  bucket = "${var.project_name}-transformed-${random_id.suffix.hex}"
}

# Enable versioning for the final bucket
resource "aws_s3_bucket_versioning" "transformed_versioning" {
  bucket = aws_s3_bucket.transformed.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket for Glue Scripts
resource "aws_s3_bucket" "scripts" {
  bucket = "${var.project_name}-scripts-${random_id.suffix.hex}"
}

# Upload the raw Python script to S3
resource "aws_s3_object" "upload_glue_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "scripts/transform_job.py"
  source = "${path.module}/glue_jobs/transform_job.py"
  # etag ensures the file re-uploads if you change the script content
  etag = filemd5("${path.module}/glue_jobs/transform_job.py")
}

resource "aws_s3_object" "manifest" {
  bucket = aws_s3_bucket.transformed.id
  key    = "manifest.json"
  content = jsonencode({
    fileLocations = [
      {
        URIPrefixes = [
          "s3://${aws_s3_bucket.transformed.id}/"
        ]
      }
    ],
    settings = {
      format = "parquet" # Or "CSV" depending on your transform_job.py output
    }
  })
}
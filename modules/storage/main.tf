# Random suffix id for dynamic bucket name creation
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 bucket creation
resource "aws_s3_bucket" "bucket" {
  bucket        = "${var.project_name}-${var.bucket_type}-${random_id.suffix.hex}"
  force_destroy = true # Added for cleanup
}

# Enable versioning for the bucket
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "versioning_cleanup" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {}

    # Best for cost saving: Permanently delete old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Abort failed uploads after 7 days to save money
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Automatically remove expired object delete markers to keep the bucket clean
    expiration {
      expired_object_delete_marker = true
    }

    # Move data to S3 Intelligent-Tiering after 0 days to automate savings
    # or move to Standard-IA (Infrequent Access) after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# Public Access Block for Buckets
resource "aws_s3_bucket_public_access_block" "bucket_privacy" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-Side Encryption for Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload the raw Python script to S3
resource "aws_s3_object" "upload_glue_script" {
  count  = var.bucket_type == "scripts" ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  key    = "scripts/transform_job.py"
  source = "${path.module}/glue_jobs/transform_job.py"
  # etag ensures the file re-uploads if you change the script content
  etag = filemd5("${path.module}/glue_jobs/transform_job.py")
}

# Upload the manifest file into S3
resource "aws_s3_object" "manifest" {
  count        = var.bucket_type == "transformed" ? 1 : 0
  bucket       = aws_s3_bucket.bucket.id
  key          = "manifest.json"
  content_type = "application/json" # This tells QuickSight it is a JSON file
  content = jsonencode({
    fileLocations = [
      {
        URIPrefixes = [
          "s3://${aws_s3_bucket.bucket.id}/transformed-data/"
        ]
      }
    ],
    globalUploadSettings = {
      format = "CSV"
    }
  })
}

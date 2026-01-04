resource "aws_s3_bucket" "raw" {
  bucket        = "${var.project_name}-raw-${random_id.suffix.hex}"
  force_destroy = true # Added for cleanup
}

resource "aws_s3_bucket" "processed" {
  bucket        = "${var.project_name}-processed-${random_id.suffix.hex}"
  force_destroy = true # Added for cleanup
}

resource "aws_s3_bucket" "transformed" {
  bucket        = "${var.project_name}-transformed-${random_id.suffix.hex}"
  force_destroy = true # Added for cleanup
}

# Bucket for Glue Scripts
resource "aws_s3_bucket" "scripts" {
  bucket        = "${var.project_name}-scripts-${random_id.suffix.hex}"
  force_destroy = true # Added for cleanup
}

# Enable versioning for the final bucket
resource "aws_s3_bucket_versioning" "transformed_versioning" {
  bucket = aws_s3_bucket.transformed.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Protects the source of truth for re-processing
resource "aws_s3_bucket_versioning" "raw_versioning" {
  bucket = aws_s3_bucket.raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Provides version control for your Glue/Lambda code
resource "aws_s3_bucket_versioning" "scripts_versioning" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
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
  bucket       = aws_s3_bucket.transformed.id
  key          = "manifest.json"
  content_type = "application/json" # This tells QuickSight it is a JSON file
  content = jsonencode({
    fileLocations = [
      {
        URIPrefixes = [
          "s3://${aws_s3_bucket.transformed.id}/transformed-data/"
        ]
      }
    ],
    globalUploadSettings = {
      format = "CSV"
    }
  })
}

# Add this to the Raw bucket resources
resource "aws_s3_bucket_lifecycle_configuration" "raw_versioning_cleanup" {
  bucket = aws_s3_bucket.raw.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {}

    # Best for cost saving: Permanently delete old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Automatically remove expired object delete markers to keep the bucket clean
    expiration {
      expired_object_delete_marker = true
    }
  }
}

# Add this to the Scripts bucket resources
resource "aws_s3_bucket_lifecycle_configuration" "scripts_versioning_cleanup" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    filter {}

    # Best for cost saving: Permanently delete old versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Automatically remove expired object delete markers to keep the bucket clean
    expiration {
      expired_object_delete_marker = true
    }
  }
}

# The "Processed" Bucket (Transient Data Cleanup)
resource "aws_s3_bucket_lifecycle_configuration" "processed_cleanup" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "delete_transient_data"
    status = "Enabled"

    filter {}

    # Delete the cleaned CSVs after 7 days
    expiration {
      days = 7
    }
  }
}

# The "Transformed" Bucket (Long-term Archiving)
resource "aws_s3_bucket_lifecycle_configuration" "transformed_savings" {
  bucket = aws_s3_bucket.transformed.id

  rule {
    id     = "archive_old_parquet"
    status = "Enabled"

    filter {}

    # Move data to S3 Intelligent-Tiering after 0 days to automate savings
    # or move to Standard-IA (Infrequent Access) after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
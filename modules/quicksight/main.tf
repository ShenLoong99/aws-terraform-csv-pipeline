# Add this block to fetch your AWS Account ID dynamically
data "aws_caller_identity" "current" {}

# Random suffix id for dynamic bucket name creation
resource "random_id" "suffix" {
  byte_length = 4
}

# Activate QuickSight Subscription
resource "aws_quicksight_account_subscription" "default" {
  account_name          = "csv-pipeline-qs-${random_id.suffix.hex}"
  authentication_method = "IAM_AND_QUICKSIGHT"
  edition               = "ENTERPRISE"
  notification_email    = var.email
}

# allow destroy even if QuickSight is still subscribed
resource "aws_quicksight_account_settings" "protection" {
  aws_account_id                 = data.aws_caller_identity.current.account_id # Add this to ensure it targets the correct account
  termination_protection_enabled = false

  depends_on = [aws_quicksight_account_subscription.default]
}

# Update the Data Source to use the dynamic ARN from the user resource
resource "aws_quicksight_data_source" "s3_source" {
  # Ensure the role and policy are ready first
  depends_on = [
    aws_quicksight_account_subscription.default,
    aws_iam_role_policy_attachment.quicksight_s3_attach
  ]

  data_source_id = "csv-pipeline-source"
  name           = "S3_Processed_Data"
  type           = "S3"

  parameters {
    s3 {
      manifest_file_location {
        bucket = var.transformed_bucket_id
        key    = var.manifest_key
      }
      # use your custom IAM role
      role_arn = aws_iam_role.quicksight_custom_role.arn
    }
  }

  permission {
    # principal = aws_quicksight_user.admin_user.arn
    principal = "arn:aws:quicksight:${var.aws_region}:${data.aws_caller_identity.current.account_id}:user/default/${split("/", data.aws_caller_identity.current.arn)[1]}"
    actions = [
      "quicksight:DescribeDataSource",
      "quicksight:DescribeDataSourcePermissions",
      "quicksight:PassDataSource",
      "quicksight:UpdateDataSource",
      "quicksight:DeleteDataSource",
      "quicksight:UpdateDataSourcePermissions"
    ]
  }
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
          var.transformed_bucket_arn,
          "${var.transformed_bucket_arn}/*"
        ]
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = [var.transformed_bucket_arn]
      }
    ]
  })
}

# Attach the policy to the standard QuickSight service role
resource "aws_iam_role_policy_attachment" "quicksight_s3_attach" {
  role       = aws_iam_role.quicksight_custom_role.name
  policy_arn = aws_iam_policy.quicksight_s3_access.arn
}

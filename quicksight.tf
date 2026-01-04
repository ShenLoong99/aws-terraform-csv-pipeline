# Activate QuickSight Subscription
resource "aws_quicksight_account_subscription" "default" {
  account_name          = "csv-pipeline-qs-${random_id.suffix.hex}"
  authentication_method = "IAM_AND_QUICKSIGHT"
  edition               = "ENTERPRISE"
  notification_email    = var.email
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
        bucket = aws_s3_bucket.transformed.id
        key    = aws_s3_object.manifest.key
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

// allow destroy even if QuickSight is still subscribed
resource "aws_quicksight_account_settings" "protection" {
  termination_protection_enabled = false
}
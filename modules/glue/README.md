<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.glue_error_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.glue_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.glue_output_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_glue_catalog_database.pipeline_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_crawler.processed_crawler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_crawler) | resource |
| [aws_glue_job.transform_job](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_job) | resource |
| [aws_glue_security_configuration.free_tier_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_security_configuration) | resource |
| [aws_iam_role.glue_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.glue_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.lambda_glue_trigger](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.glue_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy resources in | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Extra tags to pass to the provider | `map(string)` | n/a | yes |
| <a name="input_glue_script_key"></a> [glue\_script\_key](#input\_glue\_script\_key) | The key (path) of the glue script if it was uploaded | `string` | n/a | yes |
| <a name="input_lambda_exec_id"></a> [lambda\_exec\_id](#input\_lambda\_exec\_id) | ID of the IAM lambda role exec | `string` | n/a | yes |
| <a name="input_processed_bucket_arn"></a> [processed\_bucket\_arn](#input\_processed\_bucket\_arn) | ARN of S3 processed bucket | `string` | n/a | yes |
| <a name="input_processed_bucket_id"></a> [processed\_bucket\_id](#input\_processed\_bucket\_id) | ID of S3 processed bucket | `string` | n/a | yes |
| <a name="input_scripts_bucket_arn"></a> [scripts\_bucket\_arn](#input\_scripts\_bucket\_arn) | ARN of S3 scripts bucket | `string` | n/a | yes |
| <a name="input_scripts_bucket_id"></a> [scripts\_bucket\_id](#input\_scripts\_bucket\_id) | ID of S3 scripts bucket | `string` | n/a | yes |
| <a name="input_transformed_bucket_arn"></a> [transformed\_bucket\_arn](#input\_transformed\_bucket\_arn) | ARN of S3 transformed bucket | `string` | n/a | yes |
| <a name="input_transformed_bucket_id"></a> [transformed\_bucket\_id](#input\_transformed\_bucket\_id) | ID of S3 transformed bucket | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_glue_job_name"></a> [glue\_job\_name](#output\_glue\_job\_name) | Name of the glue job |
<!-- END_TF_DOCS -->
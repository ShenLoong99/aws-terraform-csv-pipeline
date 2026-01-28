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
| [aws_iam_policy.quicksight_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.quicksight_custom_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.quicksight_s3_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_quicksight_account_settings.protection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_account_settings) | resource |
| [aws_quicksight_account_subscription.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_account_subscription) | resource |
| [aws_quicksight_data_source.s3_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/quicksight_data_source) | resource |
| [random_id.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to deploy resources in | `string` | n/a | yes |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Extra tags to pass to the provider | `map(string)` | n/a | yes |
| <a name="input_email"></a> [email](#input\_email) | Email address for QuickSight notifications | `string` | n/a | yes |
| <a name="input_manifest_key"></a> [manifest\_key](#input\_manifest\_key) | The key (path) of the manifest file if it was uploaded | `string` | n/a | yes |
| <a name="input_transformed_bucket_arn"></a> [transformed\_bucket\_arn](#input\_transformed\_bucket\_arn) | ARN of S3 transformed bucket | `string` | n/a | yes |
| <a name="input_transformed_bucket_id"></a> [transformed\_bucket\_id](#input\_transformed\_bucket\_id) | ID of S3 transformed bucket | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
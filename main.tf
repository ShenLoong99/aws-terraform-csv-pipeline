# Local common tags
locals {
  common_tags = {
    Project     = "CSV-Data-Pipeline"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "ShenLoong"
  }
}

# Glue job module
module "glue" {
  source                 = "./modules/glue"
  processed_bucket_id    = module.processed_storage.bucket_id
  processed_bucket_arn   = module.processed_storage.bucket_arn
  transformed_bucket_id  = module.transformed_storage.bucket_id
  transformed_bucket_arn = module.transformed_storage.bucket_arn
  scripts_bucket_id      = module.scripts_storage.bucket_id
  scripts_bucket_arn     = module.scripts_storage.bucket_arn
  lambda_exec_id         = module.lambda.lambda_exec_id
  glue_script_key        = module.scripts_storage.upload_glue_script_key
  aws_region             = var.aws_region
  default_tags           = local.common_tags
}

# Lambda module
module "lambda" {
  source               = "./modules/lambda"
  processed_bucket_id  = module.processed_storage.bucket_id
  processed_bucket_arn = module.processed_storage.bucket_arn
  raw_bucket_id        = module.raw_storage.bucket_id
  raw_bucket_arn       = module.raw_storage.bucket_arn
  aws_region           = var.aws_region
  default_tags         = local.common_tags
}

# Quicksight module
module "quicksight" {
  source                 = "./modules/quicksight"
  email                  = var.email
  transformed_bucket_id  = module.transformed_storage.bucket_id
  manifest_key           = module.transformed_storage.manifest_key
  transformed_bucket_arn = module.transformed_storage.bucket_arn
  aws_region             = var.aws_region
  default_tags           = local.common_tags
}

# S3 Raw bucket module
module "raw_storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  bucket_type  = "raw"
  aws_region   = var.aws_region
  default_tags = local.common_tags
}

# S3 Processed bucket module
module "processed_storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  bucket_type  = "processed"
  aws_region   = var.aws_region
  default_tags = local.common_tags
}

# S3 Transformed bucket module
module "transformed_storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  bucket_type  = "transformed"
  aws_region   = var.aws_region
  default_tags = local.common_tags
}

# S3 scripts bucket module
module "scripts_storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  bucket_type  = "scripts"
  aws_region   = var.aws_region
  default_tags = local.common_tags
}

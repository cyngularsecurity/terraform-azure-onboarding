include {
  path = find_in_parent_folders()
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "my-terraform-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "my-terraform-lock-table"
  }
}

# This block will create the S3 bucket and DynamoDB table if they don't exist
generate "backend_creation" {
  path      = "backend_creation.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.state_bucket}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${local.dynamodb_table}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
EOF
}

locals {
  state_bucket   = "my-terraform-state-bucket"
  dynamodb_table = "my-terraform-lock-table"
}
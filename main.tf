provider "aws" {
  region = "ap-southeast-1"
}

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "sctp-ce10-tfstate"
    key    = "eric-ce10-tfstate" #Change this
    region = "ap-southeast-1"
  }
}

resource "aws_s3_bucket" "s3_tf" {
  bucket_prefix = "eric" # Set your bucket name here
}

resource "aws_s3_bucket_public_access_block" "s3_tf_public_access" {
  bucket = aws_s3_bucket.s3_tf.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_tf_encryption" {
  bucket = aws_s3_bucket.s3_tf.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Create a separate bucket to store access logs
resource "aws_s3_bucket" "log_bucket" {
  # checkov:skip=CKV_AWS_21:This bucket is for temporary files and does not need versioning
  bucket_prefix = "eric-tf-logs"
}



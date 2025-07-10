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
      sse_algorithm     = "aws:kms"
    }
  }
}

# Create a separate bucket to store access logs
resource "aws_s3_bucket" "log_bucket" {
  bucket_prefix = "eric-tf-logs"
}

# Enable logging on the main bucket
resource "aws_s3_bucket_logging" "s3_tf_logging" {
  bucket = aws_s3_bucket.s3_tf.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

# Create an SQS queue to receive notifications
resource "aws_sqs_queue" "s3_event_queue" {
  name_prefix = "s3-event-queue"
}

# Configure the event notification on the bucket
resource "aws_s3_bucket_notification" "s3_tf_notification" {
  bucket = aws_s3_bucket.s3_tf.id

  queue {
    queue_arn     = aws_sqs_queue.s3_event_queue.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}


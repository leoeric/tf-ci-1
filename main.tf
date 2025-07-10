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
  # checkov:skip=CKV_AWS_21:This bucket is for temporary files and does not need versioning
  bucket_prefix = "eric" # Set your bucket name here
}

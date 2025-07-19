terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ✅ ADD THIS BLOCK
  backend "s3" {
    bucket = "sctp-ce10-tfstate"      # The name of your S3 bucket
    key    = "eric-ce10-tfstate"      # The path and name for your state file in the bucket
    region = "ap-southeast-1"         # The AWS region where your bucket exists
  }
}
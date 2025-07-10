provider "aws" {
  region = "ap-southeast-1"
}


# Configure the AWS provider
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "sctp-ce10-tfstate"
    key    = "eric-ce10-tfstate" #Change this
    region = "ap-southeast-1"
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "s3_tf" {
  bucket_prefix = "eric" # Set your bucket name here
}
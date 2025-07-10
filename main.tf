provider "aws" {
  region = "ap-southeast-1"
}

# Configure the AWS provider
terraform {
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
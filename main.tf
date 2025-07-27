terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # This ensures you use a compatible version
    }
  }
}

locals {
  prefix = "eric" # Set your desired prefix here
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-southeast-1"
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

# vpc module
module "vpc" {
  version = "~> 5.0" # Ensure you use a compatible version of the VPC module
  source  = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = "10.0.0.0/16"

  azs             = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Created_by  = var.created_by
    Cohort      = "CE10"
  }
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_arn" {
  value = module.vpc.vpc_arn
}

# Create a Security Group for the S3 Service
resource "aws_security_group" "ecs_S3_service_sg" {
  name        = "${local.prefix}-ecs-S3-service-sg"
  description = "Allow traffic to the ECS S3 container"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic on port 5001 from anywhere
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: This is open to the world. Restrict if needed.
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-ecs-s3-sg"
  }
}

# Create a Security Group for the SQS Service
resource "aws_security_group" "ecs_sqs_service_sg" {
  name        = "${local.prefix}-ecs-sqs-service-sg"
  description = "Allow traffic to the ECS SQS container"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic on port 5001 from anywhere
  ingress {
    from_port   = 5002
    to_port     = 5002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: This is open to the world. Restrict if needed.
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.prefix}-ecs-sqs-sg"
  }
}


resource "aws_ecr_repository" "ecr-s3" {
  name         = "${local.prefix}-ecr-s3"
  force_delete = true
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}-ecs"
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    # Define the S3 service
    s3-service = {
      cpu    = 256
      memory = 512
      container_definitions = {
        "${local.prefix}-s3-container" = {
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${local.prefix}-ecr-s3:latest"
          port_mappings = [
            {
              containerPort = 5001
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip = true
      subnet_ids       = module.vpc.public_subnets # Correctly reference public subnets

      # ✅ SECURITY GROUP ADDED: Pass the ID of the new security group.
      security_group_ids = [aws_security_group.ecs_service_sg.id]

    }

    sqs-service = {
      cpu    = 256
      memory = 512
      container_definitions = {
        "${local.prefix}-sqs-container" = {
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${local.prefix}-ecr-sqs:latest"
          port_mappings = [
            {
              containerPort = 5002
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip = true
      subnet_ids       = module.vpc.public_subnets # Correctly reference public subnets

      # ✅ SECURITY GROUP ADDED: Pass the ID of the new security group.
      security_group_ids = [aws_security_group.ecs_service_sg.id]

    }

  }
}
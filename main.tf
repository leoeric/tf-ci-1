provider "aws" {
  region = "ap-southeast-1"
}

locals {
  prefix = "eric" # Set your desired prefix here
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# 3. Create a Security Group for the ECS Service
resource "aws_security_group" "ecs_service_sg" {
  name        = "${local.prefix}-ecs-service-sg"
  description = "Allow traffic to the ECS container"
  vpc_id      = "vpc-0d89969d63958a1fc"

  # Allow inbound traffic on port 8080 from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "${local.prefix}-ecs-sg"
  }
}

resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
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
    "${local.prefix}-taskdefinition" = {
      cpu    = 512
      memory = 1024
      container_definitions = {
        "${local.prefix}-container" = {
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.prefix}-ecr:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100

      # ✅ SUBNETS ADDED: Pass the IDs of the subnets you created.
      subnet_ids = [
        "subnet-085e1089341f1aaa9",
        "subnet-0a9ad1569e0f18a9a"
      ]

      # ✅ SECURITY GROUP ADDED: Pass the ID of the new security group.
      security_group_ids = [aws_security_group.ecs_service_sg.id]
    }
  }
}
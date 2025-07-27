variable "vpc_name" {
  description = "The ID of the VPC"
  type        = string
  default     = "eric-vpc-tf-module"
}

variable "created_by" {
  description = "The name of vpc creator"
  type        = string
  default     = "eric"
}

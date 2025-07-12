# variables.tf

variable "domain_name" {
  description = "The custom domain name for the API Gateway (e.g., group1-urlshortener.sctp-sandbox.com)"
  type        = string
  default     = "group1-urlshortener.sctp-sandbox.com"
}

variable "hosted_zone_name" {
  description = "The name of the Route 53 Hosted Zone (e.g., sctp-sandbox.com)"
  type        = string
  default     = "sctp-sandbox.com"
}

# This assumes your API Gateway is created in another file.
# You will need to replace this with your actual API Gateway resource.
resource "aws_api_gateway_rest_api" "api" {
  name = "url-shortener-api"
}
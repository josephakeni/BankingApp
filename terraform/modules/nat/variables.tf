variable "vpc_id" {
  description = "ID of the VPC where NAT Gateways will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Two public subnet IDs (index 0 = eu-west-1a, index 1 = eu-west-1b) where NAT Gateways are placed"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) == 2
    error_message = "Exactly two public subnet IDs are required (one per AZ)."
  }
}

variable "private_subnet_ids" {
  description = "Two private subnet IDs (index 0 = eu-west-1a, index 1 = eu-west-1b) that need outbound internet access"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) == 2
    error_message = "Exactly two private subnet IDs are required (one per AZ)."
  }
}

variable "tags" {
  description = "Tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}

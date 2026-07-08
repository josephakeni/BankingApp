variable "vpc_name" {
  description = "Value of the Name tag on the existing VPC"
  type        = string
  default     = "main_vpc"
}

variable "tags" {
  description = "Tags to propagate to any resources created by this module"
  type        = map(string)
  default     = {}
}

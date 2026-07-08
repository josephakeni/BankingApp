output "vpc_id" {
  description = "ID of the main VPC"
  value       = data.aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the main VPC"
  value       = data.aws_vpc.main.cidr_block
}

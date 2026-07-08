output "nat_gateway_ids" {
  description = "NAT Gateway IDs indexed by AZ (0 = eu-west-1a, 1 = eu-west-1b)"
  value       = aws_nat_gateway.this[*].id
}

output "nat_public_ips" {
  description = "Elastic IP addresses assigned to each NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

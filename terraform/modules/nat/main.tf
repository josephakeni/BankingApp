# One Elastic IP per AZ — needed before the NAT Gateway can be created.
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "nat-eip-${count.index == 0 ? "eu-west-1a" : "eu-west-1b"}"
  })
}

# One NAT Gateway per AZ placed in the corresponding public subnet.
# Both private subnets currently share rtb-020b99fa00ddcf205. The eu-west-1b
# private subnet is re-associated to a new route table below so that each AZ
# routes through its own NAT Gateway (AZ-level fault isolation).
resource "aws_nat_gateway" "this" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.public_subnet_ids[count.index]

  tags = merge(var.tags, {
    Name = "nat-gw-${count.index == 0 ? "eu-west-1a" : "eu-west-1b"}"
  })

  depends_on = [aws_eip.nat]
}

# ---------------------------------------------------------------------------
# eu-west-1a: add 0.0.0.0/0 → NAT-1a to the existing private route table.
# The data source looks up the table by subnet association at plan time so
# the table ID does not need to be hard-coded.
# ---------------------------------------------------------------------------
data "aws_route_table" "private_a" {
  subnet_id = var.private_subnet_ids[0]
}

resource "aws_route" "private_a_nat" {
  route_table_id         = data.aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

# ---------------------------------------------------------------------------
# eu-west-1b: new dedicated route table so this AZ can use NAT-1b instead
# of routing through eu-west-1a. The private_subnet_ids[1] subnet is moved
# to this new table via the association resource below.
# ---------------------------------------------------------------------------
resource "aws_route_table" "private_b" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "private-rt-eu-west-1b"
  })
}

resource "aws_route" "private_b_nat" {
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[1].id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = var.private_subnet_ids[1]
  route_table_id = aws_route_table.private_b.id
}

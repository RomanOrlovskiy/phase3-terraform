/**
 * Outputs
 */

// The VPC ID
output "vpc_id" {
  value = "${aws_vpc.main.id}"
}

// The VPC CIDR
output "cidr_block" {
  value = "${aws_vpc.main.cidr_block}"
}

// A comma-separated list of subnet IDs.
output "external_subnets" {
  value = aws_subnet.external.*.id
}

output "internal_subnets" {
  value = aws_subnet.internal.*.id
}

// The list of availability zones of the VPC.
output "availability_zones" {
  value = aws_subnet.external.*.availability_zone
}

// The list of EIPs associated with the internal subnets.
output "internal_nat_ips" {
  value = aws_eip.nat.*.public_ip
}
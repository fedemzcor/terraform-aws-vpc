output "vpc_id" {
  value = aws_vpc.prod_vpc.id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public.*.id
}
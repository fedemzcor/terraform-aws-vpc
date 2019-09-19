locals {
  public_subnet_count =  length(data.aws_availability_zones.available.names)
}
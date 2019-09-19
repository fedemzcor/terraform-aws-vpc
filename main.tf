provider "aws" {

    region = var.region
}

resource "aws_vpc" "prod_vpc" {
    cidr_block = var.cidr_block
    tags = {
        Name = "${var.namespace}-vpc"
    }

}


resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.available)
  vpc_id            = aws_vpc.prod_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  cidr_block = cidrsubnet(
    signum(length(var.cidr_block)) == 1 ? var.cidr_block : "1.0.0.0/16",
    ceil(log(local.public_subnet_count * 2, 2)),
    local.public_subnet_count + count.index
  
  )
  tags = {
      Name = "${var.namespace}-public-subnet"
  }
}

resource "aws_route_table" "public" {


  #count  = signum(length(aws_vpc.prod_vpc.default_route_table_id)) == 1 ? 0 : 1

  vpc_id = aws_vpc.prod_vpc.id
  tags = {
      Name = "${var.namespace}-public-route-table"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.prod_vpc.id}"

  tags = {
      Name = "${var.namespace}-vpc"
  }
}

resource "aws_route" "public" {
  #count  = signum(length(aws_vpc.prod_vpc.default_route_table_id)) == 1 ? 0 : 1
  #route_table_id         = join("", aws_route_table.public.*.id)
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public" {
  count  = length(data.aws_availability_zones.available)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
  #route_table_id = aws_route_table.public[0].id
}

/*
resource "aws_route_table_association" "public_default" {
  count  = signum(length(aws_vpc.prod_vpc.default_route_table_id)) == 1 ? length(data.aws_availability_zones.available) : 0
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_vpc.prod_vpc.default_route_table_id
}
*/


resource "aws_network_acl" "public" {
 
  vpc_id     = aws_vpc.prod_vpc.id
  subnet_ids = aws_subnet.public.*.id

  egress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  ingress {
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
  }

  tags = {
      Name = "${var.namespace}-subnet-network-acl"
  }
}
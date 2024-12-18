provider "aws" {
    region="${var.region}"
}

terraform {
    backend "s3" {}
}

resource "aws_vpc" "production_vpc" {
    cidr_block              = "${var.vpc_cidr}"
    enable_dns_hostnames    = true

    tags = {
        Name = "t-ws-middleware-VPC"
  }
}

resource "aws_subnet" "public-subnet-1" {
    cidr_block        = "${var.public_subnet_1_cidr}"
    vpc_id            = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-1a"

    tags = {
        Name = "t-ws-public-sn-1"
    }
}

resource "aws_subnet" "public-subnet-2" {
    cidr_block        = "${var.public_subnet_2_cidr}"
    vpc_id            = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-1b"

    tags = {
        Name = "t-ws-public-sn-2"
    }
}

resource "aws_subnet" "public-subnet-3" {
    cidr_block        = "${var.public_subnet_3_cidr}"
    vpc_id            = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-1c"

    tags = {
        Name = "t-ws-public-sn-3"
    }
}

resource "aws_subnet" "private-subnet-1" {
    cidr_block        = "${var.private_subnet_1_cidr}"
    vpc_id            = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-1a"

    tags = {
        Name = "t-ws-private-sn-1"
    }
}

resource "aws_subnet" "private-subnet-2" {
    cidr_block        = "${var.private_subnet_2_cidr}"
    vpc_id            = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-1b"

    tags = {
        Name = "t-ws-private-sn-2"
    }
}

resource "aws_subnet" "private-subnet-3" {
    cidr_block        = "${var.private_subnet_3_cidr}"
    vpc_id            = "${aws_vpc.production_vpc.id}"
    availability_zone = "us-east-1c"

    tags = {
        Name = "t-ws-private-sn-3"
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id  = "${aws_vpc.production_vpc.id}"
    tags    = {
        Name = "t-ws-public-rtb"
    }
}

resource "aws_route_table" "private_route_table" {
    vpc_id  = "${aws_vpc.production_vpc.id}"
    tags    = {
        Name = "t-ws-private-rtb"
    }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  route_table_id    = "${aws_route_table.public_route_table.id}"
  subnet_id         = "${aws_subnet.public-subnet-1.id}"
}

resource "aws_route_table_association" "public_subnet_2_association" {
  route_table_id    = "${aws_route_table.public_route_table.id}"
  subnet_id         = "${aws_subnet.public-subnet-2.id}"
}

resource "aws_route_table_association" "public_subnet_3_association" {
  route_table_id    = "${aws_route_table.public_route_table.id}"
  subnet_id         = "${aws_subnet.public-subnet-3.id}"
}

resource "aws_route_table_association" "private_subnet_1_association" {
  route_table_id    = "${aws_route_table.private_route_table.id}"
  subnet_id         = "${aws_subnet.private-subnet-1.id}"
}

resource "aws_route_table_association" "private_subnet_2_association" {
  route_table_id    = "${aws_route_table.private_route_table.id}"
  subnet_id         = "${aws_subnet.private-subnet-2.id}"
}

resource "aws_route_table_association" "private_subnet_3_association" {
  route_table_id    = "${aws_route_table.private_route_table.id}"
  subnet_id         = "${aws_subnet.private-subnet-3.id}"
}

resource "aws_eip" "elastic_ip_for_nat_gw" {
  associate_with_private_ip = "10.0.0.5"
  tags                      = {
    Nmme = "t-ws-prod-eip"
  }
} 

resource "aws_nat_gateway" "nat_gw" {
    allocation_id   = "${aws_eip.elastic_ip_for_nat_gw.id}"
    subnet_id       = "${aws_subnet.public-subnet-1.id}"
    tags            = {
      Name = "t-ws-prod-ngw"
    }
    depends_on = [ aws_eip.elastic_ip_for_nat_gw ]
}

resource "aws_route" "nat_gw_route" {
    route_table_id          = "${aws_route_table.private_route_table.id}"
    nat_gateway_id          = "${aws_nat_gateway.nat_gw.id}"
    destination_cidr_block  = "0.0.0.0/0"
}

resource "aws_internet_gateway" "production_igw" {
    vpc_id  = "${aws_vpc.production_vpc.id}"
    tags    = {
      Name = "t-ws-prod-igw"
    }
}

resource "aws_route" "public_igw_route" {
    route_table_id          = "${aws_route_table.public_route_table.id}"
    gateway_id              = "${aws_internet_gateway.production_igw.id}" 
    destination_cidr_block  = "0.0.0.0/0"
}
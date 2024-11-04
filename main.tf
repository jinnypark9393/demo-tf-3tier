# 버전 설정
terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }

  required_version = "> 0.12" // 0.12 버전 이후 형식
}

# AWS Provider 설정
provider "aws" {
  region = "us-west-2"
}

# VPC 생성
resource "aws_vpc" "demo-3tier" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "demo-3tier"
  }
}

# Public Subnet1 생성
resource "aws_subnet" "demo-3tier-public1" {
  vpc_id = aws_vpc.demo-3tier.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "us-west-2a"

  tags = {
    Name = "demo-3tier-public1"
  }
}

# Public Subnet2 생성
resource "aws_subnet" "demo-3tier-public2" {
  vpc_id = aws_vpc.demo-3tier.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "us-west-2b"

  tags = {
    Name = "demo-3tier-public2"
  }
}

# Private Subnet1 생성
resource "aws_subnet" "demo-3tier-private1" {
  vpc_id = aws_vpc.demo-3tier.id
  cidr_block = "10.0.100.0/24"

  availability_zone = "us-west-2a"

  tags = {
    Name = "demo-3tier-private1"
  }
}

# Private Subnet2 생성
resource "aws_subnet" "demo-3tier-private2" {
  vpc_id = aws_vpc.demo-3tier.id
  cidr_block = "10.0.101.0/24"

  availability_zone = "us-west-2b"

  tags = {
    Name = "demo-3tier-private2"
  }
}

# Private Subnet3 생성
resource "aws_subnet" "demo-3tier-private3" {
  vpc_id = aws_vpc.demo-3tier.id
  cidr_block = "10.0.102.0/24"

  availability_zone = "us-west-2a"

  tags = {
    Name = "demo-3tier-private3"
  }
}

# Private Subnet4 생성
resource "aws_subnet" "demo-3tier-private4" {
  vpc_id = aws_vpc.demo-3tier.id
  cidr_block = "10.0.103.0/24"

  availability_zone = "us-west-2b"

  tags = {
    Name = "demo-3tier-private4"
  }
}

# Internet Gateway 생성
resource "aws_internet_gateway" "demo-3tier-igw" {
    vpc_id = aws_vpc.demo-3tier.id

    tags = {
      Name = "demo-3tier-igw"
    }
}

# Public Subnet Route table 생성
resource "aws_route_table" "demo-3tier-rt-public" {
  vpc_id = aws_vpc.demo-3tier.id

  tags = {
    Name = "demo-3tier-rt"
  }
}

# Public Route table 및 Subnet 연결
resource "aws_route_table_association" "demo-3tier-rt-asso-public1" {
  subnet_id = aws_subnet.demo-3tier-public1.id
  route_table_id = aws_route_table.demo-3tier-rt-public.id
}

resource "aws_route_table_association" "demo-3tier-rt-asso-public2" {
  subnet_id = aws_subnet.demo-3tier-public2.id
  route_table_id = aws_route_table.demo-3tier-rt-public.id
}

# Public Route 설정
resource "aws_route" "demo-3tier-route-public" {
  route_table_id = aws_route_table.demo-3tier-rt-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.demo-3tier-igw.id
}

# EIP for NAT Gateway
resource "aws_eip" "demo-3tier-eip-nat" {
  domain = "vpc"

  tags = {
    Name = "demo-3tier-eip-nat" 
  }
}

# NAT Gateway 설정
resource "aws_nat_gateway" "demo-3tier-nat" {
  allocation_id = aws_eip.demo-3tier-eip-nat.id
  subnet_id = aws_subnet.demo-3tier-public1.id
  
  tags = {
    Name = "demo-3tier-nat"
  }
}

# Private Subnet Route table 생성
resource "aws_route_table" "demo-3tier-rt-private" {
  vpc_id = aws_vpc.demo-3tier.id

  tags = {
    Name = "demo-3tier-rt-private"
  }
}

# Private Route table 및 Subnet 연결
resource "aws_route_table_association" "demo-3tier-rt-asso-private1" {
  subnet_id = aws_subnet.demo-3tier-private1.id
  route_table_id = aws_route_table.demo-3tier-rt-private.id
}

resource "aws_route_table_association" "demo-3tier-rt-asso-private2" {
  subnet_id = aws_subnet.demo-3tier-private2.id
  route_table_id = aws_route_table.demo-3tier-rt-private.id
}

resource "aws_route_table_association" "demo-3tier-rt-asso-private3" {
  subnet_id = aws_subnet.demo-3tier-private3.id
  route_table_id = aws_route_table.demo-3tier-rt-private.id
}

resource "aws_route_table_association" "demo-3tier-rt-asso-private4" {
  subnet_id = aws_subnet.demo-3tier-private4.id
  route_table_id = aws_route_table.demo-3tier-rt-private.id
}


# Private Route 설정
resource "aws_route" "demo-3tier-route-private" {
  route_table_id = aws_route_table.demo-3tier-rt-private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.demo-3tier-nat.id
}

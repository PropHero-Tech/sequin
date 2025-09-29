# Use existing infrastructure VPC instead of creating new one
data "aws_vpc" "sequin-main" {
  id = "vpc-0ca08e43d1d97331d"  # Infrastructure VPC
}

# Use existing public subnets (for ALB)
data "aws_subnet" "sequin-public-primary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sequin-main.id]
  }
  filter {
    name   = "availability-zone"
    values = [var.primary_availability_zone]
  }
  filter {
    name   = "tag:Scheme"
    values = ["public"]
  }
}

data "aws_subnet" "sequin-public-secondary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sequin-main.id]
  }
  filter {
    name   = "availability-zone"
    values = [var.secondary_availability_zone]
  }
  filter {
    name   = "tag:Scheme"
    values = ["public"]
  }
}

# Use existing private subnets (for ECS tasks)
data "aws_subnet" "sequin-private-primary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sequin-main.id]
  }
  filter {
    name   = "availability-zone"
    values = [var.primary_availability_zone]
  }
  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

data "aws_subnet" "sequin-private-secondary" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sequin-main.id]
  }
  filter {
    name   = "availability-zone"
    values = [var.secondary_availability_zone]
  }
  filter {
    name   = "tag:Scheme"
    values = ["private"]
  }
}

# Use existing public subnets list (for ALB)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.sequin-main.id] 
  }
  filter {
    name   = "tag:Scheme"
    values = ["public"]
  }
}
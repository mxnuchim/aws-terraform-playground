resource "aws_vpc" "primary_vpc" {
  cidr_block       = var.primary_vpc_cidr
  provider         = aws.primary
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "Primary Vpc ${var.primary_region}"
    }
  )
}

resource "aws_vpc" "secondary_vpc" {
  cidr_block       = var.secondary_vpc_cidr
  provider         = aws.secondary
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "Secondary Vpc ${var.secondary_region}"
    }
  )
}

resource "aws_subnet" "primary_subnet" {
  provider = aws.primary
  vpc_id     = aws_vpc.primary_vpc.id
  cidr_block = var.primary_subnet_cidr
  availability_zone = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true


  tags = merge(
    local.common_tags,
    {
      Name = "Primary-Subnet-${var.primary_region}"
    }
  )
}

resource "aws_subnet" "secondary_subnet" {
  provider = aws.secondary
  vpc_id     = aws_vpc.secondary_vpc.id
  cidr_block = var.secondary_subnet_cidr
  availability_zone = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true


  tags = merge(
    local.common_tags,
    {
      Name = "Secondary-Subnet-${var.secondary_region}"
    }
  )
}

resource "aws_internet_gateway" "primary_igw" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "Primary-IGW-${var.primary_region}"
    }
  )
}
 
resource "aws_internet_gateway" "secondary_igw" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "Secondary-IGW-${var.secondary_region}"
    }
  )
}

resource "aws_route_table" "primary_rt" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "Primary-RT-${var.primary_region}"
    }
  )
}

resource "aws_route_table" "secondary_rt" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "Secondary-RT-${var.secondary_region}"
    }
  )
}

resource "aws_route_table_association" "primary_rt_association" {
  provider = aws.primary
  subnet_id = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

resource "aws_route_table_association" "secondary_rt_association" {
  provider = aws.secondary
  subnet_id = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

resource "aws_vpc_peering_connection" "primary_to_secondary_pc" {
  provider = aws.primary
  vpc_id = aws_vpc.primary_vpc.id
  peer_region = var.secondary_region
  peer_vpc_id = aws_vpc.secondary_vpc.id
  # peer_owner_id = data.aws_caller_identity.secondary.account_id
  auto_accept = false

  tags = merge(
    local.common_tags,
    {
      Name = "Primary-Secondary-PC-${var.primary_region}-${var.secondary_region}"
    }
  )
}

resource "aws_vpc_peering_connection_accepter" "secondary_accepter" {
  provider = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_pc.id
  auto_accept = true

  depends_on = [ aws_vpc_peering_connection.primary_to_secondary_pc ]
  tags = merge(
    local.common_tags,
    {
      Name = "Secondary-Accepter-${var.secondary_region}-${var.primary_region}"
    }
  )
}

resource "aws_route" "primary_to_secondary_route" {
  provider = aws.primary
  route_table_id = aws_route_table.primary_rt.id
  destination_cidr_block = aws_vpc.secondary_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_pc.id

  depends_on = [ aws_vpc_peering_connection.primary_to_secondary_pc ]
}

resource "aws_route" "secondary_to_primary_route" {
  provider = aws.secondary
  route_table_id = aws_route_table.secondary_rt.id
  destination_cidr_block = aws_vpc.primary_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_pc.id

  depends_on = [ aws_vpc_peering_connection.primary_to_secondary_pc ]
 
}


# Security Group for Primary VPC EC2 instance
resource "aws_security_group" "primary_sg" {
  provider    = aws.primary
  name        = "primary-vpc-sg"
  description = "Security group for Primary VPC instance"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  ingress {
    description = "All traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Primary-VPC-SG"
    Environment = "Demo"
  }
}

# Security Group for Secondary VPC EC2 instance
resource "aws_security_group" "secondary_sg" {
  provider    = aws.secondary
  name        = "secondary-vpc-sg"
  description = "Security group for Secondary VPC instance"
  vpc_id      = aws_vpc.secondary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  ingress {
    description = "All traffic from Primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Secondary-VPC-SG"
    Environment = "Demo"
  }
}


# EC2 Instance in Primary VPC
resource "aws_instance" "primary_instance" {
  provider               = aws.primary
  ami                    = data.aws_ami.primary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  key_name               = var.primary_key_name

  user_data = local.primary_user_data

  tags = {
    Name        = "Primary-VPC-Instance"
    Environment = "Demo"
    Region      = var.primary_region
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

# EC2 Instance in Secondary VPC
resource "aws_instance" "secondary_instance" {
  provider               = aws.secondary
  ami                    = data.aws_ami.secondary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.secondary_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  key_name               = var.secondary_key_name

  user_data = local.secondary_user_data

  tags = {
    Name        = "Secondary-VPC-Instance"
    Environment = "Demo"
    Region      = var.secondary_region
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}


  
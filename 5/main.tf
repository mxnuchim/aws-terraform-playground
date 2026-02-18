resource "aws_s3_bucket" "dev_bucket" {
  bucket = local.bucket_name

  tags = merge(
    local.common_tags,
    {
      Name = "${local.environment} S3 Bucket"
    }
  )
}

resource "aws_vpc" "dev_vpc" {
  cidr_block = local.vpc_cidr_block

  tags = merge(
    local.common_tags,
    {
      Name = "${local.environment}-vpc"
    }
  )
}

resource "aws_instance" "dev_ec2" {
  count = var.instance_count
  ami           = "ami-0c1fe732b5494dc14"
  instance_type = var.instance_type
  monitoring = var.monitoring_enabled
  associate_public_ip_address = var.associate_public_ip_address

  tags = merge(
    local.common_tags,
    {
      Name = "${local.environment}-ec2"
    }
  )
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.cidr_block[0]
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
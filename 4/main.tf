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
  ami           = "ami-0c1fe732b5494dc14"
  instance_type = "t3.micro"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.environment}-ec2"
    }
  )
}

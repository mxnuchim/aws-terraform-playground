terraform {

  backend "s3" {
    bucket = "aws-terraform-playground-demo-bucket"
    key = "dev/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.32.1"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

resource "aws_s3_bucket" "dev_bucket" {
  bucket = "dev-bucket-oliver-2.0"

  tags = {
    Name        = "Dev S3 Bucket 2.0"
    Environment = "Dev"
  }
}
terraform {
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

resource "aws_vpc" "example_vpc" {
    cidr_block = "10.0.0.0/16"
}
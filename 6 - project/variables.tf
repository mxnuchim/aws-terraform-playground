variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "company" {
  description = "Company name for resource naming"
  type        = string
}

variable "bucket_name" {
  description = "Bucket name for the S3 bucket"
  type        = string
}

variable "default_region" {
  description = "AWS region"
  type        = string
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.dev_s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.dev_bucket.bucket
}


  



  
  

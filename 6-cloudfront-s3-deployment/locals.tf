locals {
  region         = var.default_region
  environment    = var.environment
  bucket_name    = "${var.environment}-bucket-${var.company}"
  vpc_cidr_block = "10.0.0.0/16"
  allowed_vm_types = ["t2.micro", "t2.small", "t3.micro", "t3.small"]
  s3_origin_id = "${var.environment}-s3-${aws_s3_bucket.dev_bucket.id}"
  my_domain = "mxnuchim.com"

  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Company     = var.company
  }
}


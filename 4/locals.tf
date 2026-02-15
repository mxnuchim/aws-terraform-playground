locals {
  region         = var.region
  environment    = var.environment
  bucket_name    = "${var.environment}-bucket-${var.company}"
  vpc_cidr_block = "10.0.0.0/16"
  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Company     = var.company
  }
}

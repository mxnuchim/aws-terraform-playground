locals {

  users = csvdecode(file("users.csv"))
  
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Company     = var.company
  }

}


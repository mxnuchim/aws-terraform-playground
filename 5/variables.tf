variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "company" {
  description = "Company name for resource naming"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "monitoring_enabled" {
  description = "Enable CloudWatch monitoring"
  type        = bool
}

variable "associate_public_ip_address" {
  description = "Associate public IP address with the instance"
  type        = bool
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/16", "192.168.0.0/16"]
}

variable "allowed_vm_types" {
  description = "Allowed VM types"
  type        = list(string)
  default     = ["t2.micro", "t2.small", "t3.micro", "t3.small"]
}


  
  

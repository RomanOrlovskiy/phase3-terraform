variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
}

variable "external_subnets_cidr" {
  description = "List of external subnets"
  type        = "list"
}

variable "internal_subnets_cidr" {
  description = "List of internal subnets"
  type        = "list"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = "list"
}

variable "name" {
  description = "Name tag, e.g stack"  
}

variable "name" {
  description = "the name of your stack"
  default     = "phase3-tf-stack"
}

variable "environment" {
  description = "the name of your environment"
  default     = "dev-west2"
}

variable "key_name" {
  description = "the name of the ssh key to use"
  default     = "WebServer01"
}

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well"
  default     = "10.192.0.0/16"
}

variable "internal_subnets_cidr" {
  description = "a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.192.20.0/24", "10.192.21.0/24"]
}

variable "external_subnets_cidr" {
  description = "a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.192.10.0/24", "10.192.11.0/24"]
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well"
  default     = ["us-west-2a", "us-west-2b"]
}

variable "certificate_arn" {
  description = "SSL Certificate"
  default     = "arn:aws:acm:us-west-2:414831080620:certificate/d01732be-d3f4-481f-b94a-a4eedb2af2eb"
}

variable "database_name" {
  description = "Database name"
  default     = "petclinc"
}

variable "database_user" {
  description = "The database admin account username"
  default     = "petclinc_user"
}
variable "database_password" {
  description = "The database admin account password"
  default     = "petclinc_password"
}

variable "container_image_name" {
  default = "414831080620.dkr.ecr.us-west-2.amazonaws.com/petclinic"
}

variable "image_version" {
  default = "2.1.27"
}

variable "container_hard_memory_limit" {
  description = "Hard memory limit for container"
  default     = "360"
}

variable "container_port" {
  description = "Port to open on the container for LB connection"
  default     = "8080"
}

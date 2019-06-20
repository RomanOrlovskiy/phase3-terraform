provider "aws" {
  region  = "${var.region}"
}

variable "name" {
  description = "the name of your stack"
  default = "phase3-tf-stack"
}

variable "environment" {
  description = "the name of your environment"
  default = "dev-west2"
}

# variable "key_name" {
#   description = "the name of the ssh key to use, e.g. \"internal-key\""
# }

variable "region" {
  description = "the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default"
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well"
  default     = "10.30.0.0/16"
}

variable "internal_subnets_cidr" {
  description = "a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.30.0.0/19" ,"10.30.64.0/19"]
}

variable "external_subnets_cidr" {
  description = "a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones"
  default     = ["10.30.32.0/20", "10.30.96.0/20"]
}

variable "availability_zones" {
  description = "a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well"
  default     = ["us-west-2a", "us-west-2b"]
}

module "aws-network" {
  source             = "./modules/aws-network"
  name               = "${var.name}"
  vpc_cidr               = "${var.vpc_cidr}"
  internal_subnets_cidr   = "${var.internal_subnets_cidr}"
  external_subnets_cidr   = "${var.external_subnets_cidr}"
  availability_zones = "${var.availability_zones}"
  environment        = "${var.environment}"
}
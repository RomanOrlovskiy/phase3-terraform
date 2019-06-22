provider "aws" {
  region = "${var.region}"
}

variable "name" {
  description = "the name of your stack"
  default     = "phase3-tf-stack"
}

variable "environment" {
  description = "the name of your environment"
  default     = "dev-west2"
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
  default = "latest"
}


module "aws_network" {
  source                = "./modules/aws_network"
  name                  = "${var.name}"
  vpc_cidr              = "${var.vpc_cidr}"
  internal_subnets_cidr = "${var.internal_subnets_cidr}"
  external_subnets_cidr = "${var.external_subnets_cidr}"
  availability_zones    = "${var.availability_zones}"
  environment           = "${var.environment}"
}

module "rds" {
  source            = "./modules/rds"
  environment       = "${var.environment}"
  allocated_storage = "20"
  db_name           = "${var.database_name}"
  db_user           = "${var.database_user}"
  db_password       = "${var.database_password}"
  internal_subnets  = module.aws_network.internal_subnets
  vpc               = "${module.aws_network.id}"
  db_instance_class = "db.t2.micro"
  db_engine         = "mysql"
  db_engine_version = "5.7"
  db_family         = "mysql5.7"
}

module "ecs_cluster" {
  source                   = "./modules/ecs_cluster"
  name                     = "${var.name}"
  environment              = "${var.environment}"
  instance_type            = "t2.micro"
  cluster_size_max         = "4"
  cluster_size             = "2"
  ssh_key_name             = "WebServer01.pem"
  internal_subnets         = module.aws_network.internal_subnets
  ecs_hosts_security_group = module.rds.db_access_sg_id
  alert_phone_number       = "+380635321012"
  alert_email              = "romanorlovskiy92@gmail.com"

}


module "petclinic" {
  source                    = "./modules/ecs_services/petclinic"
  name                      = "${var.name}"
  environment               = "${var.environment}"
  image_version             = "${var.image_version}"
  task_desired_count        = "2"
  task_max_count            = "4"
  path                      = "/"
  https_listener            = "${module.ecs_cluster.https_listener}"
  container_image_name      = "${var.container_image_name}"
  ecs_cluster_id            = "${module.ecs_cluster.ecs_cluster_id}"
  default_target_group_arn  = "${module.ecs_cluster.default_target_group_arn}"
  container_name            = "petclinic"
  task_definition_file_path = "petclinic_task_definition.tpl"
  database_type             = "mysql"
  jdbc_url                  = "${module.ecs_cluster.jdbc_url}"
  db_username               = "${var.database_user}"
  db_password               = "${var.database_password}"
  aws_region                = "${var.region}"
  ecs_service_asg_role      = "${module.ecs_cluster.ecs_service_asg_role}"
}

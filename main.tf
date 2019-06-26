provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "phase3-terraform-petclinic"
    key    = "terraform11.tfstate"
    region = "us-west-2"
  }
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

module "ecs_cluster" {
  source             = "./modules/ecs_cluster"
  name               = "${var.name}"
  environment        = "${var.environment}"
  instance_type      = "${var.instance_type}"
  cluster_size_max   = "${var.cluster_size_max}"
  cluster_size       = "${var.cluster_size}"
  ssh_key_name       = "${var.key_name}"
  internal_subnets   = "${module.aws_network.internal_subnets}"
  external_subnets   = "${module.aws_network.external_subnets}"
  certificate_arn    = "${var.certificate_arn}"
  alert_phone_number = "${var.alert_phone_number}"
  alert_email        = "${var.alert_email}"
  vpc_id             = "${module.aws_network.vpc_id}"
}

module "rds" {
  name                        = "${var.name}"
  source                      = "./modules/rds"
  environment                 = "${var.environment}"
  allocated_storage           = "${var.db_allocated_storage}"
  db_name                     = "${var.database_name}"
  db_user                     = "${var.database_user}"
  db_password                 = "${var.database_password}"
  internal_subnets            = "${module.aws_network.internal_subnets}"
  ecs_hosts_security_group_id = "${module.ecs_cluster.ecs_hosts_security_group_id}"
  vpc_id                      = "${module.aws_network.vpc_id}"
  db_instance_class           = "${var.db_instance_class}"
  db_engine                   = "${var.db_engine}"
  db_engine_version           = "${var.db_engine_version}"
  db_family                   = "${var.db_family}"
}

module "petclinic" {
  source                      = "./modules/ecs_services/petclinic"
  name                        = "${var.name}"
  environment                 = "${var.environment}"
  image_version               = "${var.image_version}"
  container_hard_memory_limit = "${var.container_hard_memory_limit}"
  container_port              = "${var.container_port}"
  task_desired_count          = "${var.service_task_desired_count}"
  task_max_count              = "${var.service_task_max_count}"
  path                        = "${var.path_for_alb}"
  https_listener              = "${module.ecs_cluster.https_listener}"
  container_image_name        = "${var.container_image_name}"
  ecs_cluster_name            = "${module.ecs_cluster.ecs_cluster_name}"
  ecs_cluster_id              = "${module.ecs_cluster.ecs_cluster_id}"
  default_tg_arn_suffix       = "${module.ecs_cluster.default_tg_arn_suffix}"
  default_target_group_arn    = "${module.ecs_cluster.default_target_group_arn}"
  container_name              = "${var.container_name}"
  task_definition_file_path   = "${var.task_definition_file_path}"
  database_type               = "${var.db_engine}"
  jdbc_url                    = "${module.rds.jdbc_url}"
  db_username                 = "${var.database_user}"
  db_password                 = "${var.database_password}"
  aws_region                  = "${var.region}"
  ecs_service_asg_role        = "${module.ecs_cluster.ecs_service_asg_role}"
}
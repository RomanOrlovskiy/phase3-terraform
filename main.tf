provider "aws" {
  region = "${var.region}"
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
  instance_type      = "t2.micro"
  cluster_size_max   = "4"
  cluster_size       = "2"
  ssh_key_name       = "${var.key_name}"
  internal_subnets   = module.aws_network.internal_subnets
  external_subnets   = module.aws_network.external_subnets
  certificate_arn    = "${var.certificate_arn}"
  alert_phone_number = "+380635321012"
  alert_email        = "romanorlovskiy92@gmail.com"
  vpc_id             = "${module.aws_network.vpc_id}"
}

module "rds" {
  name                        = "${var.name}"
  source                      = "./modules/rds"
  environment                 = "${var.environment}"
  allocated_storage           = "20"
  db_name                     = "${var.database_name}"
  db_user                     = "${var.database_user}"
  db_password                 = "${var.database_password}"
  internal_subnets            = module.aws_network.internal_subnets
  ecs_hosts_security_group_id = module.ecs_cluster.ecs_hosts_security_group_id
  vpc_id                      = "${module.aws_network.vpc_id}"
  db_instance_class           = "db.t2.micro"
  db_engine                   = "mysql"
  db_engine_version           = "5.7"
  db_family                   = "mysql5.7"
}

module "petclinic" {
  source                      = "./modules/ecs_services/petclinic"
  name                        = "${var.name}"
  environment                 = "${var.environment}"
  image_version               = "${var.image_version}"
  container_hard_memory_limit = "${var.container_hard_memory_limit}"
  container_port              = "${var.container_port}"
  task_desired_count          = "2"
  task_max_count              = "4"
  path                        = "/"
  https_listener              = "${module.ecs_cluster.https_listener}"
  container_image_name        = "${var.container_image_name}"
  ecs_cluster_name            = "${module.ecs_cluster.ecs_cluster_name}"
  ecs_cluster_id              = "${module.ecs_cluster.ecs_cluster_id}"
  default_tg_arn_suffix       = "${module.ecs_cluster.default_tg_arn_suffix}"
  default_target_group_arn    = "${module.ecs_cluster.default_target_group_arn}"
  container_name              = "petclinic-service"
  task_definition_file_path   = "petclinic_task_definition.tpl"
  database_type               = "mysql"
  jdbc_url                    = "${module.rds.jdbc_url}"
  db_username                 = "${var.database_user}"
  db_password                 = "${var.database_password}"
  aws_region                  = "${var.region}"
  ecs_service_asg_role        = "${module.ecs_cluster.ecs_service_asg_role}"
}
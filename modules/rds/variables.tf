variable "name" {
  description = "Stack name"
}

variable "environment" {
  description = "The environment"
}
variable "db_name" {
  description = "Database name"
}

variable "db_user" {
  description = "The database admin account username"
}
variable "db_password" {
  description = "The database admin account password"
}

variable "allocated_storage" {
  description = "The size of the database (Gb)"
  default     = "20"
}

variable "db_instance_class" {
  description = "The database instance type"
  default     = "db.t2.micro"
}

variable "multi_az" {
  default     = false
  description = "Muti-az allowed?"
}

variable "db_engine" {
  description = "Database engine (mysql, aurora, postgres, etc)"
}

variable "db_engine_version" {
  description = "DB engine version"
}

variable "db_family" {
  description = "DB family"
}

variable "vpc_id" {
  description = "Choose to which VPC the security groups should be deployed to"
}

variable "internal_subnets" {
  description = "Choose in which subnets this RDS instance should be deployed to"
  type = "list"
}

variable "ecs_hosts_security_group_id" {
  description = "The EC2 security group that contains instances that need access to"
}
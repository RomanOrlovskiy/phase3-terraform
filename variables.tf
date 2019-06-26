
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
  default     = "petclinic"
}

variable "database_user" {
  description = "The database admin account username"
  default     = "petclinic_user"
}
variable "database_password" {
  description = "The database admin account password"
  default     = "petclinic_password"
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

variable "instance_type" {
  description = "ECS host instance type"
  default = "t2.micro"
}

variable "cluster_size_max" {
  description = "Max amount of instances in ECS cluster"
  default = "4"  
}

variable "cluster_size" {
  description = "Min/default amount of instances in the ECS cluster"
  default = "2"  
}

variable "alert_phone_number" {
  description = "Phone number for SMS notifications on ECS hosts auto scalling"
  default = "+380635321012"
}

variable "alert_email" {
  description = "Email for notifications on container auto scaling"
  default = "romanorlovskiy92@gmail.com"
}

variable "db_allocated_storage" {
  description = "Storage for RDS in GB"
  default = "20"
}

variable "db_instance_class" {
  description = "Instance class for RDS"
  default = "db.t2.micro"
}

variable "db_engine" {
  description = "RDS engine"
  default = "mysql"  
}

variable "db_engine_version" {
  description = "RDS engine version"
  default = "5.7"
}

variable "db_family" {
  description = "RDS family"
  default = "mysql5.7"
  
}

variable "service_task_desired_count" {
  description = "Desired amount of tasks to run in ECS"
  default = "2"
}

variable "service_task_max_count" {
  description = "Max amount of tasks to run in ECS service"
  default = "10"
}

variable "path_for_alb" {
  description = "The path to register with the Application Load Balancer"
  default = "/"
}

variable "container_name" {
  description = "Name of the container for ECS service task"
  default = "petclinic-service"
}

variable "task_definition_file_path" {
  description = "Relative path to the task definition file"
  default = "petclinic_task_definition.tpl"
}

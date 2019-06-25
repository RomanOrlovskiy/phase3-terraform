variable "name" {
  description = "Infrastructure name"
}

variable "environment" {
  description = "Environment name"
}

variable "image_version" {
  description = "Petclinic application version to be deployed"
  default     = "latest"
}

variable "container_hard_memory_limit" {
  description = "Hard memory limit for the container"
}

variable "container_port" {
  description = "Port to open on the container"
}


variable "task_desired_count" {
  description = "How many instances of this task should we run across our cluster?"
}

variable "task_max_count" {
  description = "Maximum number of instances of this task we can run across our cluster"
}

variable "path" {
  description = "The path to register with the Application Load Balancer"
  default     = "/"
}

variable "container_image_name" {
  description = "Docker container image name"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
}

variable "ecs_cluster_id" {
  description = "ARN of the ECS cluster"
}

variable "default_tg_arn_suffix" {
  description = "Name of the default target group for the Application load balancer"
}

variable "default_target_group_arn" {
  description = "ARN of the default target group for the Application load balancer"
}

variable "container_name" {
  description = "ECS service task container name"
}

variable "task_definition_file_path" {
  description = "Path to JSON template for service task definition"
}

variable "database_type" {
  description = "Database type for containers to connect to"
}

variable "jdbc_url" {
  description = "JDBC URL of the database"
}

variable "db_username" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
}

variable "aws_region" {
  description = "AWS Region"
}

variable "ecs_service_asg_role" {
  description = "ECS Service ASG role ARN"
}

variable "https_listener" {

}
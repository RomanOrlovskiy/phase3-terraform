variable "name" {
  description = "Name"
}

variable "environment" {
  description = "An environment name"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "instance_type" {
  description = "Which instance type should we use to build the ECS cluster?"
  default     = "t2.micro"
}

variable "cluster_size_max" {
  description = "Max amount of ECS hosts to deploy"
  default     = "4"
}

variable "cluster_size" {
  description = "Amount of ECS hosts to deploy initialy"
  default     = "2"
}

variable "ssh_key_name" {
  description = "SSH key to access ECS hosts"
}

variable "certificate_arn" {
  description = "SSL Certificate"
}

variable "internal_subnets" {
  description = "Choose which subnets this ECS cluster should be deployed to"
}

variable "external_subnets" {
  description = "Subnets for ALB"
}

variable "alert_phone_number" {
  description = "Add this initial cell for SMS notification of EC2 instance scale up/down alerts"
}

variable "alert_email" {
  description = "The email address of the admin who receives alerts."
}
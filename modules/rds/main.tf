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

variable "vpc" {
  description = "Choose to which VPC the security groups should be deployed to"
}

variable "internal_subnets" {
  description = "Choose in which subnets this RDS instance should be deployed to"
  #type = "list"
}

resource "aws_db_instance" "mysql_rds" {
  name                            = "${var.db_name}"
  allocated_storage               = "${var.allocated_storage}"
  instance_class                  = "${var.db_instance_class}"
  engine                          = "${var.db_engine}"
  engine_version                  = "${var.db_engine_version}"
  multi_az                        = "${var.multi_az}"
  username                        = "${var.db_user}"
  password                        = "${var.db_password}"
  db_subnet_group_name            = "${aws_db_subnet_group.rds_subnet_group.id}"
  parameter_group_name            = "${aws_db_parameter_group.main.id}"
  vpc_security_group_ids          = ["${aws_security_group.rds_sg.id}"]
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = ["error"]

  tags = {
    Environment = "${var.environment}"
  }
}

/* Security Group for resources that want to access the Database */
resource "aws_security_group" "db_access_sg" {
  vpc_id      = "${var.vpc}"
  name        = "${var.environment}-db-access-sg"
  description = "Allow access to RDS"

  tags = {
    Name        = "${var.environment}-db-access-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "rds_sg" {
  vpc_id = "${var.vpc}"

  //allow traffic for TCP
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.db_access_sg.id}"]
  }

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_db_parameter_group" "main" {
  family = "${var.db_family}"

  parameter {
    name  = "log_output"
    value = "FILE"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.internal_subnets

  tags = {
    Environment = "${var.environment}"
  }
}


output "db_access_sg_id" {
  value = "${aws_security_group.db_access_sg.id}"
}

output "db_user" {
  value = "${var.db_user}"
}

output "db_password" {
  value = "${var.db_password}"
}

#Compose JDBC URL to pass to the containers
# output "jdbc_url" {
#   value = "${join("", ["jdbc:${aws_db_instance.mysql_rds.engine}://", aws_db_instance.mysql_rds.address, ":", aws_db_instance.mysql_rds.port, "/", aws_db_instance.mysql_rds.name ])}"
# }

output "jdbc_url" {
  value = "jdbc:${aws_db_instance.mysql_rds.engine}://${aws_db_instance.mysql_rds.endpoint}/${aws_db_instance.mysql_rds.name}"
}

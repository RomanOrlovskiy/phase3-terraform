output "db_user" {
  value = "${var.db_user}"
}

output "db_password" {
  value = "${var.db_password}"
}

output "jdbc_url" {
  value = "jdbc:${aws_db_instance.mysql_rds.engine}://${aws_db_instance.mysql_rds.endpoint}/${aws_db_instance.mysql_rds.name}"
}
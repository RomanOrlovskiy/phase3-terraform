output "alb_fullname" {
  value = "${aws_lb.alb.name}"
}

output "alb_url" {
  value = "${aws_lb.alb.dns_name}"
}

output "https_listener" {
  value = "${aws_alb_listener.https_listener.id}"
}

output "default_target_group_arn" {
  value = "${aws_lb_target_group.alb_target_group.arn}"
}

output "default_tg_arn_suffix" {
  value = "${aws_lb_target_group.alb_target_group.arn_suffix}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.main.name}"
}

output "ecs_cluster_id" {
  value = "${aws_ecs_cluster.main.id}"
}

output "ecs_service_asg_role" {
  value = "${aws_iam_role.asg_role.arn}"
}

output "ecs_hosts_security_group_id" {
  value = "${aws_security_group.ecs_sg.id}"
}

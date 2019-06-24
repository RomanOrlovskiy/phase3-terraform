variable "name" {
  description = "Infrastructure name"
}

variable "environment" {
  description = "Environment name"
}

variable "image_version" {
  description = "Petclinic application version to be deployed"
  default = "latest"
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

variable "ecs_cluster_id" {
  description = "ARN of the ECS cluster"
}

variable "default_target_group_name" {
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


resource "aws_ecs_service" "service" {
  name            = "${var.name}-service"
  depends_on      = ["aws_lb_listener_rule.rule"]
  cluster         = "${var.ecs_cluster_id}"
  iam_role        = "${aws_iam_role.ecs_service_role.arn}"
  desired_count   = "${var.task_desired_count}"
  task_definition = "${aws_ecs_task_definition.service_task.arn}"

  load_balancer {
    target_group_arn = "${var.default_target_group_arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }
}

resource "aws_ecs_task_definition" "service_task" {
  family                = "${var.container_name}"
  container_definitions = "${data.template_file.task.rendered}"
}

data "template_file" "task" {
  template = "${file("${path.module}/${var.task_definition_file_path}")}"
  vars = {
    CONTAINER_NAME = "${var.container_name}"
    IMAGE = "${var.container_image_name}:${var.image_version}"
    MEMORY = "${var.container_hard_memory_limit}"
    CONTAINER_PORT = "${var.container_port}"
    DATABASE                   = "${var.database_type}"
    SPRING_DATASOURCE_URL      = "${var.jdbc_url}"
    SPRING_DATASOURCE_USERNAME = "${var.db_username}"
    SPRING_DATASOURCE_PASSWORD = "${var.db_password}"
    awslogs-group              = "${aws_cloudwatch_log_group.group.id}"
    awslogs-region             = "${var.aws_region}"
  }
}

resource "aws_cloudwatch_log_group" "group" {
  name              = "${var.name}-log-group"
  retention_in_days = 365
}

resource "aws_lb_listener_rule" "rule" {
  listener_arn = "${var.https_listener}"
  priority     = 1

  condition {
    field  = "path-pattern"
    values = ["${var.path}"]
  }

  action {
    target_group_arn = "${var.default_target_group_arn}"
    type             = "forward"
  }
}


# This IAM Role grants the service access to register/unregister with the
# Application Load Balancer (ALB). It is based on the default documented here:
# http://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_IAM_role.html

resource "aws_iam_role" "ecs_service_role" {
  name               = "${var.name}-ecs-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.service_policy_document.json}"
}

data "aws_iam_policy_document" "service_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

# ATTACH IAM POLICIES TO THE IAM ROLE

resource "aws_iam_role_policy" "ecs_service_permissions" {
  name   = "${var.name}-ecs-service-permissions"
  role   = "${aws_iam_role.ecs_service_role.id}"
  policy = "${data.aws_iam_policy_document.ecs_service_permissions_document.json}"

}

data "aws_iam_policy_document" "ecs_service_permissions_document" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:RegisterTargets"
    ]
  }
}

#SCALING CONTAINERS OF THE SERVICE
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = "${var.task_max_count}"
  min_capacity       = "${var.task_desired_count}"
  resource_id        = "service/${var.ecs_cluster_id}/${aws_ecs_service.service.name}"
  role_arn           = "${var.ecs_service_asg_role}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "service_scale_up" {
  name        = "${var.name}-service-scale-up"
  policy_type = "StepScaling"
  resource_id = "${aws_appautoscaling_target.ecs_target.resource_id}"

  scalable_dimension = "${aws_appautoscaling_target.ecs_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 2
    }
  }
}

resource "aws_appautoscaling_policy" "service_scale_down" {
  name        = "${var.name}-service-scale-down"
  policy_type = "StepScaling"
  resource_id = "${aws_appautoscaling_target.ecs_target.resource_id}"

  scalable_dimension = "${aws_appautoscaling_target.ecs_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 180
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -2
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_up" {
  alarm_name          = "${var.name}-scale-up-on-100-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"

  dimensions = {
    TargetGroup = "${var.default_target_group_name}"
  }

  alarm_description = "Alarm if request count is more than 100 requests per Target per one period"
  alarm_actions     = ["${aws_appautoscaling_policy.service_scale_up.arn}"]

}

resource "aws_cloudwatch_metric_alarm" "scale_down" {
  alarm_name          = "${var.name}-scal-edown-on-10-requests"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"

  dimensions = {
    TargetGroup = "${var.default_target_group_name}"
  }

  alarm_description = "Alarm if request count is less than 10 requests per Target per one period"
  alarm_actions     = ["${aws_appautoscaling_policy.service_scale_down.arn}"]

}

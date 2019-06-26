data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.name}-ecs-cluster"

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.name}-ecs-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_policy_document.json}"

  # aws_iam_instance_profile.ecs_instance sets create_before_destroy to true, which means every resource it depends on,
  # including this one, must also set the create_before_destroy flag to true, or you'll get a cyclic dependency error.
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ecs_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# To attach an IAM Role to an EC2 Instance, you use an IAM Instance Profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.name}-ecs-instance-profile"
  role = "${aws_iam_role.ecs_instance_role.name}"

  # aws_launch_configuration.ecs_instance sets create_before_destroy to true, which means every resource it depends on,
  # including this one, must also set the create_before_destroy flag to true, or you'll get a cyclic dependency error.
  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH IAM POLICIES TO THE IAM ROLE
# The IAM policy allows an ECS Agent running on each EC2 Instance to communicate with the ECS scheduler.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role_policy" "ecs_cluster_permissions" {
  name   = "${var.name}-ecs-cluster-permissions"
  role   = "${aws_iam_role.ecs_instance_role.id}"
  policy = "${data.aws_iam_policy_document.ecs_cluster_permissions_document.json}"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ecs_cluster_permissions_document" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken"
    ]
  }
}

#Attach AWS managed policy to the ECS role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment_cloudwatch" {
  role       = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# ---------------------------------------------------------------------------------------------------------------------
#ALB
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.alb_sg.id}"]
  subnets            = var.external_subnets

  tags = {
    Environment = "${var.environment}"
  }
}

# Security group for ALB 
# This security group defines who/where is allowed to access the Application Load Balancer.
resource "aws_security_group" "alb_sg" {
  name        = "${var.name}-alb-sg"
  description = "Allow HTTPS from Anywhere into ALB"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment}"
  }
}

resource "random_id" "target_group_sufix" {
  byte_length = 2
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.name}-tg-${random_id.target_group_sufix.hex}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  depends_on        = ["aws_lb_target_group.alb_target_group"]
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
    type             = "forward"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------------------------------------------------
#ASG
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "main" {
  depends_on           = ["aws_ecs_cluster.main"]
  name                 = "${var.name}-asg"
  vpc_zone_identifier  = "${var.internal_subnets}"
  launch_configuration = "${aws_launch_configuration.launch_configuration.name}"
  min_size             = "${var.cluster_size}"
  max_size             = "${var.cluster_size_max}"
  desired_capacity     = "${var.cluster_size}"


  tags = [
    {
      key                 = "Name"
      value               = "${var.name}"
      propagate_at_launch = true
    }, 
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    }
  ]

}

/* Security Group for ECS */
resource "aws_security_group" "ecs_sg" {
  vpc_id      = "${var.vpc_id}"
  name        = "${var.name}-ecs-sg"
  description = "Allow egress from container"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_launch_configuration" "launch_configuration" {
  image_id             = "${data.aws_ami.ecs.id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.ssh_key_name}"
  security_groups      = ["${aws_security_group.ecs_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance_profile.name}"
  user_data            = "${data.template_file.user_data.rendered}"

  # Important note: whenever using a launch configuration with an auto scaling group, you must set
  # create_before_destroy = true. However, as soon as you set create_before_destroy = true in one resource, you must
  # also set it in every resource that it depends on, or you'll get an error about cyclic dependencies (especially when
  # removing resources). For more info, see:
  #
  # https://www.terraform.io/docs/providers/aws/r/launch_configuration.html
  # https://terraform.io/docs/configuration/resources.html
  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/user_data.sh")}"

  vars = {
    cluster_name = "${aws_ecs_cluster.main.name}"
  }
}

#Create IAM Role for Autoscalling group
resource "aws_iam_role" "asg_role" {
  name               = "${var.name}-asg-role"
  assume_role_policy = "${data.aws_iam_policy_document.asg_policy_document.json}"
}

data "aws_iam_policy_document" "asg_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "asg_permissions" {
  name   = "${var.name}-asg-permissions"
  role   = "${aws_iam_role.asg_role.id}"
  policy = "${data.aws_iam_policy_document.asg_permissions_document.json}"
}

data "aws_iam_policy_document" "asg_permissions_document" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "application-autoscaling:*",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
#SCALING ASG AND CONTAINERS
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_sns_topic" "sms_alert" {
  name = "sms-topic"
}

resource "aws_sns_topic_subscription" "sms_alert_subscription" {
  topic_arn = "${aws_sns_topic.sms_alert.arn}"
  protocol  = "sms"
  endpoint  = "${var.alert_phone_number}"
}

resource "aws_autoscaling_policy" "scale_up" {
  name                    = "${var.name}-scale-up"
  adjustment_type         = "ChangeInCapacity"
  policy_type             = "StepScaling"
  metric_aggregation_type = "Average"
  autoscaling_group_name  = "${aws_autoscaling_group.main.name}"

  step_adjustment {
    scaling_adjustment          = 1
    metric_interval_lower_bound = 0
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                    = "${var.name}-scale-down"
  adjustment_type         = "ChangeInCapacity"
  policy_type             = "StepScaling"
  metric_aggregation_type = "Average"
  autoscaling_group_name  = "${aws_autoscaling_group.main.name}"

  step_adjustment {
    scaling_adjustment          = -1
    metric_interval_lower_bound = 0
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name}-memoryreservation-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale up if the memory reservation is above 70% for 5 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}", "${aws_sns_topic.sms_alert.arn}"]

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name          = "${var.name}-memoryreservation-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "35"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale down if the memory reservation is below 35% for 5 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_down.arn}", "${aws_sns_topic.sms_alert.arn}"]

  lifecycle {
    create_before_destroy = true
  }
}
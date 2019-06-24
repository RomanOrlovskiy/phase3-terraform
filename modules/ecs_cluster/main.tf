variable "name" {
  description = "Name"
}

variable "environment" {
  description = "An environment name that will be prefixed to resource names"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "instance_type" {
  description = "Which instance type should we use to build the ECS cluster?"
  default = "t2.micro"
}

variable "cluster_size_max" {
  description = "Max amount of ECS hosts to deploy"
  default = "4"
}

variable "cluster_size" {
  description = "Amount of ECS hosts to deploy initialy"
  default = "2"
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

variable "ecs_hosts_security_group" {
  description = "elect the Security Group to use for the ECS cluster hosts"
}

variable "alert_phone_number" {
  description = "Add this initial cell for SMS notification of EC2 instance scale up/down alerts"
}

variable "alert_email" {
  description = "The email address of the admin who receives alerts."
}

data "aws_ami" "ecs" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
}

# variable "ecs_ami" {
#   description = "ECS-Optimized AMI ID"
# }

# resource "aws_sns_topic" "email_alert" {
  
# }

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
    Name = "${var.name}-alb-sg"
  }
}

resource "random_id" "target_group_sufix" {
  byte_length = 2
}

resource "aws_alb_target_group" "alb_target_group" {
  name        = "${var.name}-alb-target-group-${random_id.target_group_sufix.hex}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "https_listener" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  depends_on        = ["aws_alb_target_group.alb_target_group"]
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    type             = "forward"
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
  #suspended_processes

  tags = [
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
    security_groups = ["${aws_security_group.alb_sg.name}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-ecs-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_launch_configuration" "launch_configuration" {
  name          = "${var.name}-LC"
  image_id      = "${data.aws_ami.ecs.id}"
  instance_type = "${var.instance_type}"
  #iam_instance_profile        = "${var.enable_iam_setup ? element(concat(aws_iam_instance_profile.instance_profile.*.name, list("")), 0) : var.iam_instance_profile_name}"
  key_name        = "${var.ssh_key_name}"
  security_groups = ["${var.ecs_hosts_security_group}"]

  # A shell script that will execute when on each EC2 instance when it first boots to configure the ECS Agent to talk
  # to the right ECS cluster
  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.main.name}" >> /etc/ecs/ecs.config

#Install CloudWatch agent to store logs of all containers in one group
yum install -y https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
EOF

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

#Create IAM Role for Autoscalling group
resource "aws_iam_role" "asg_role" {
  name = "${var.name}-asg-role"
  assume_role_policy = "${data.aws_iam_policy_document.asg_policy_document.json}"    
}

data "aws_iam_policy_document" "asg_policy_document" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "asg_permissions" {
  name = "${var.name}-asg-permissions"
  role = "${aws_iam_role.asg_role.id}"
  policy = "${data.aws_iam_policy_document.asg_permissions_document.json}"
}

data "aws_iam_policy_document" "asg_permissions_document" {
  statement {
    effect = "Allow"
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

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  policy_type = "StepScaling"
  metric_aggregation_type = "Average"
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  policy_type = "StepScaling"
  metric_aggregation_type = "Average"
  autoscaling_group_name = "${aws_autoscaling_group.main.name}"

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
  statistic           = "Avarage"
  threshold           = "70"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale up if the memory reservation is above 90% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_up.arn}"]

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
  statistic           = "Avarage"
  threshold           = "35"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.main.name}"
  }

  alarm_description = "Scale down if the memory reservation is below 35% for 5 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.scale_down.arn}"]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_ecs_cluster" "main" {
  name = "${var.name}-ecs-cluster"

  tags = {
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.name}-ecs-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_policy_document.json}"    

  # aws_iam_instance_profile.ecs_instance sets create_before_destroy to true, which means every resource it depends on,
  # including this one, must also set the create_before_destroy flag to true, or you'll get a cyclic dependency error.
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ecs_policy_document" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
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
  name = "${var.name}-ecs-cluster-permissions"
  role = "${aws_iam_role.ecs_instance_role.id}"
  policy = "${data.aws_iam_policy_document.ecs_cluster_permissions_document.json}"
  
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "ecs_cluster_permissions_document" {
  statement {
    effect = "Allow"
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
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment_ssm" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment_cloudwatch" {
  role = "${aws_iam_role.ecs_instance_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

output "alb_fullname" {
  value = "${aws_lb.alb.name}"
}

output "alb_url" {
  value = "${aws_lb.alb.dns_name}"
}

output "alb_https_listener" {
  value = "${aws_alb_listener.https_listener.id}"
}

output "default_target_group" {
  value = "${aws_alb_target_group.alb_target_group.id}"
}

output "default_target_group_name" {
  value = "${aws_alb_target_group.alb_target_group.name}"
}

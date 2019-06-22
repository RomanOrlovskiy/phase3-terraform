variable "name" {
  description = "Name"
}

variable "environment" {
  description = "An environment name that will be prefixed to resource names"
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

variable "internal_subnets" {
  description = "Choose which subnets this ECS cluster should be deployed to"
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


resource "aws_autoscaling_group" "main" {
  depends_on = ["aws_ecs_cluster.main"]
  name = "${var.environment}-asg"
  vpc_zone_identifier = "${var.internal_subnets}"
  launch_configuration = "${aws_launch_configuration.launch_configuration.name}"
  min_size = "${var.cluster_size}"
  max_size = "${var.cluster_size_max}"
  desired_capacity = "${var.cluster_size}"  
  #suspended_processes

  tags = [
    {
      key                 = "Environment"
      value               = "${var.environment}"
      propagate_at_launch = true
    }
  ]

}

resource "aws_launch_configuration" "launch_configuration" {
  name   = "${var.environment}-LC"
  image_id      = "${data.aws_ami.ecs.id}"
  instance_type = "${var.instance_type}"  
  #iam_instance_profile        = "${var.enable_iam_setup ? element(concat(aws_iam_instance_profile.instance_profile.*.name, list("")), 0) : var.iam_instance_profile_name}"
  key_name                    = "${var.ssh_key_name}"
  security_groups             = ["${var.ecs_hosts_security_group}"]
  
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
# ASG AND CONTAINER SCALING
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

  alarm_description = "Scale up if the memory reservation is above 70% for 5 minutes"
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

output "ecs_cluster_id" {
  value = "${aws_ecs_cluster.main.id}"
}

output "default_target_group_arn" {
  value = "default_target_group_arn"
}

output "ecs_service_asg_role" {
  value = "${aws_iam_role.asg_role.arn}"
}

output "jdbc_url" {
  value = "jdbc_url"
}

output "https_listener" {
  value = "https_listener"
}


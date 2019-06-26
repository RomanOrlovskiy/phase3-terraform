## Notice

This template was created for learning purposes only. Use with caution.

## Description

The template deploys a VPC, with a pair of public and private subnets spread
across two Availabilty Zones. It deploys an Internet Gateway, with a default
route on the public subnets. It deploys a pair of NAT Gateways (one in each AZ),
and default routes for them in the private subnets.

It then deploys a highly available ECS cluster using an AutoScaling Group, with
ECS hosts distributed across multiple Availability Zones.

Also it deploys RDS which will is used by containers in ECS service.

The template includes scaling of EC2 instances in ASG based on MemoryReservation CloudWatch metric as well as scaling of containers in ECS based on RequestCountPerTarget metric. There is an SMS notification configured for ASG scaling.

Additionally, logs from the EC2 instances are sent to CloudWatch.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alert\_email | Email for notifications on container auto scaling | string | `""` | no |
| alert\_phone\_number | Phone number for SMS notifications on ECS hosts auto scalling | string | `""` | no |
| availability\_zones | a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well | list | `<list>` | no |
| certificate\_arn | SSL Certificate | string | `"arn:aws:acm:us-west-2:414831080620:certificate/d01732be-d3f4-481f-b94a-a4eedb2af2eb"` | no |
| cluster\_size | Min/default amount of instances in the ECS cluster | string | `"2"` | no |
| cluster\_size\_max | Max amount of instances in ECS cluster | string | `"4"` | no |
| container\_hard\_memory\_limit | Hard memory limit for container | string | `"360"` | no |
| container\_image\_name |  | string | `"414831080620.dkr.ecr.us-west-2.amazonaws.com/petclinic"` | no |
| container\_name | Name of the container for ECS service task | string | `"petclinic-service"` | no |
| container\_port | Port to open on the container for LB connection | string | `"8080"` | no |
| database\_name | Database name | string | `"petclinic"` | no |
| database\_password | The database admin account password | string | `"petclinic_password"` | no |
| database\_user | The database admin account username | string | `"petclinic_user"` | no |
| db\_allocated\_storage | Storage for RDS in GB | string | `"20"` | no |
| db\_engine | RDS engine | string | `"mysql"` | no |
| db\_engine\_version | RDS engine version | string | `"5.7"` | no |
| db\_family | RDS family | string | `"mysql5.7"` | no |
| db\_instance\_class | Instance class for RDS | string | `"db.t2.micro"` | no |
| environment | the name of your environment | string | `"dev-west2"` | no |
| external\_subnets\_cidr | a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones | list | `<list>` | no |
| image\_version |  | string | `"2.1.27"` | no |
| instance\_type | ECS host instance type | string | `"t2.micro"` | no |
| internal\_subnets\_cidr | a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones | list | `<list>` | no |
| key\_name | the name of the ssh key to use | string | `"WebServer01"` | no |
| name | the name of your stack | string | `"phase3-tf-stack"` | no |
| path\_for\_alb | The path to register with the Application Load Balancer | string | `"/"` | no |
| region | the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default | string | `"us-west-2"` | no |
| service\_task\_desired\_count | Desired amount of tasks to run in ECS | string | `"2"` | no |
| service\_task\_max\_count | Max amount of tasks to run in ECS service | string | `"10"` | no |
| task\_definition\_file\_path | Relative path to the task definition file | string | `"petclinic_task_definition.tpl"` | no |
| vpc\_cidr | the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well | string | `"10.192.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| service\_url | Application Load balancer URL |


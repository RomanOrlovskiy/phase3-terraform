## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alert\_email | The email address of the admin who receives alerts. | string | n/a | yes |
| alert\_phone\_number | Add this initial cell for SMS notification of EC2 instance scale up/down alerts | string | n/a | yes |
| certificate\_arn | SSL Certificate | string | n/a | yes |
| cluster\_size | Amount of ECS hosts to deploy initialy | string | `"2"` | no |
| cluster\_size\_max | Max amount of ECS hosts to deploy | string | `"4"` | no |
| environment | An environment name | string | n/a | yes |
| external\_subnets | Subnets for ALB | string | n/a | yes |
| instance\_type | Which instance type should we use to build the ECS cluster? | string | `"t2.micro"` | no |
| internal\_subnets | Choose which subnets this ECS cluster should be deployed to | string | n/a | yes |
| name | Name | string | n/a | yes |
| ssh\_key\_name | SSH key to access ECS hosts | string | n/a | yes |
| vpc\_id | VPC id | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| alb\_fullname |  |
| alb\_url |  |
| default\_target\_group\_arn |  |
| default\_tg\_arn\_suffix |  |
| ecs\_cluster\_id |  |
| ecs\_cluster\_name |  |
| ecs\_hosts\_security\_group\_id |  |
| ecs\_service\_asg\_role |  |
| https\_listener |  |


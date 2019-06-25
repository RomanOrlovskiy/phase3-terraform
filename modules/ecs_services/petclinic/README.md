## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | AWS Region | string | n/a | yes |
| container\_hard\_memory\_limit | Hard memory limit for the container | string | n/a | yes |
| container\_image\_name | Docker container image name | string | n/a | yes |
| container\_name | ECS service task container name | string | n/a | yes |
| container\_port | Port to open on the container | string | n/a | yes |
| database\_type | Database type for containers to connect to | string | n/a | yes |
| db\_password | Database password | string | n/a | yes |
| db\_username | Database username | string | n/a | yes |
| default\_target\_group\_arn | ARN of the default target group for the Application load balancer | string | n/a | yes |
| default\_tg\_arn\_suffix | Name of the default target group for the Application load balancer | string | n/a | yes |
| ecs\_cluster\_id | ARN of the ECS cluster | string | n/a | yes |
| ecs\_cluster\_name | Name of the ECS cluster | string | n/a | yes |
| ecs\_service\_asg\_role | ECS Service ASG role ARN | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| https\_listener |  | string | n/a | yes |
| image\_version | Petclinic application version to be deployed | string | `"latest"` | no |
| jdbc\_url | JDBC URL of the database | string | n/a | yes |
| name | Infrastructure name | string | n/a | yes |
| path | The path to register with the Application Load Balancer | string | `"/"` | no |
| task\_definition\_file\_path | Path to JSON template for service task definition | string | n/a | yes |
| task\_desired\_count | How many instances of this task should we run across our cluster? | string | n/a | yes |
| task\_max\_count | Maximum number of instances of this task we can run across our cluster | string | n/a | yes |


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allocated\_storage | The size of the database (Gb) | string | `"20"` | no |
| db\_engine | Database engine (mysql, aurora, postgres, etc) | string | n/a | yes |
| db\_engine\_version | DB engine version | string | n/a | yes |
| db\_family | DB family | string | n/a | yes |
| db\_instance\_class | The database instance type | string | `"db.t2.micro"` | no |
| db\_name | Database name | string | n/a | yes |
| db\_password | The database admin account password | string | n/a | yes |
| db\_user | The database admin account username | string | n/a | yes |
| ecs\_hosts\_security\_group\_id | The EC2 security group that contains instances that need access to | string | n/a | yes |
| environment | The environment | string | n/a | yes |
| internal\_subnets | Choose in which subnets this RDS instance should be deployed to | string | n/a | yes |
| multi\_az | Muti-az allowed? | string | `"false"` | no |
| name | Stack name | string | n/a | yes |
| vpc\_id | Choose to which VPC the security groups should be deployed to | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| db\_password |  |
| db\_user |  |
| jdbc\_url |  |


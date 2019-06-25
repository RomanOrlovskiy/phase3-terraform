## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| availability\_zones | a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well | list | `<list>` | no |
| certificate\_arn | SSL Certificate | string | `"arn:aws:acm:us-west-2:414831080620:certificate/d01732be-d3f4-481f-b94a-a4eedb2af2eb"` | no |
| container\_hard\_memory\_limit | Hard memory limit for container | string | `"360"` | no |
| container\_image\_name |  | string | `"414831080620.dkr.ecr.us-west-2.amazonaws.com/petclinic"` | no |
| container\_port | Port to open on the container for LB connection | string | `"8080"` | no |
| database\_name | Database name | string | `"petclinc"` | no |
| database\_password | The database admin account password | string | `"petclinc_password"` | no |
| database\_user | The database admin account username | string | `"petclinc_user"` | no |
| environment | the name of your environment | string | `"dev-west2"` | no |
| external\_subnets\_cidr | a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones | list | `<list>` | no |
| image\_version |  | string | `"2.1.27"` | no |
| internal\_subnets\_cidr | a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones | list | `<list>` | no |
| key\_name | the name of the ssh key to use | string | `"WebServer01"` | no |
| name | the name of your stack | string | `"phase3-tf-stack"` | no |
| region | the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default | string | `"us-west-2"` | no |
| vpc\_cidr | the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well | string | `"10.192.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| service\_url | Application Load balancer URL |


VPC

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| availability\_zones | List of availability zones | list | n/a | yes |
| environment | Environment tag, e.g prod | string | n/a | yes |
| external\_subnets\_cidr | List of external subnets | list | n/a | yes |
| internal\_subnets\_cidr | List of internal subnets | list | n/a | yes |
| name | Name tag, e.g stack | string | n/a | yes |
| vpc\_cidr | The CIDR block for the VPC. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| availability\_zones | The list of availability zones of the VPC. |
| cidr\_block | The VPC CIDR |
| external\_subnets | A comma-separated list of subnet IDs. |
| internal\_nat\_ips | The list of EIPs associated with the internal subnets. |
| internal\_subnets |  |
| vpc\_id | The VPC ID |


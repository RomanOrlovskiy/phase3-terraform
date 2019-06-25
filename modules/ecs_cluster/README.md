## Required Inputs

The following input variables are required:

## Optional Inputs

The following input variables are optional (have default values):

### availability\_zones

Description: a comma-separated list of availability zones, defaults to all AZ of the region, if set to something other than the defaults, both internal_subnets and external_subnets have to be defined as well

Type: `list`

Default: `<list>`

### certificate\_arn

Description: SSL Certificate

Type: `string`

Default: `"arn:aws:acm:us-west-2:414831080620:certificate/d01732be-d3f4-481f-b94a-a4eedb2af2eb"`

### container\_hard\_memory\_limit

Description: Hard memory limit for container

Type: `string`

Default: `"360"`

### container\_image\_name

Description:

Type: `string`

Default: `"414831080620.dkr.ecr.us-west-2.amazonaws.com/petclinic"`

### container\_port

Description: Port to open on the container for LB connection

Type: `string`

Default: `"8080"`

### database\_name

Description: Database name

Type: `string`

Default: `"petclinc"`

### database\_password

Description: The database admin account password

Type: `string`

Default: `"petclinc_password"`

### database\_user

Description: The database admin account username

Type: `string`

Default: `"petclinc_user"`

### environment

Description: the name of your environment

Type: `string`

Default: `"dev-west2"`

### external\_subnets\_cidr

Description: a list of CIDRs for external subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones

Type: `list`

Default: `<list>`

### image\_version

Description:

Type: `string`

Default: `"2.1.27"`

### internal\_subnets\_cidr

Description: a list of CIDRs for internal subnets in your VPC, must be set if the cidr variable is defined, needs to have as many elements as there are availability zones

Type: `list`

Default: `<list>`

### key\_name

Description: the name of the ssh key to use

Type: `string`

Default: `"WebServer01"`

### name

Description: the name of your stack

Type: `string`

Default: `"phase3-tf-stack"`

### region

Description: the AWS region in which resources are created, you must set the availability_zones variable as well if you define this value to something other than the default

Type: `string`

Default: `"us-west-2"`

### vpc\_cidr

Description: the CIDR block to provision for the VPC, if set to something other than the default, both internal_subnets and external_subnets have to be defined as well

Type: `string`

Default: `"10.192.0.0/16"`

## Outputs

The following outputs are exported:

### service\_url

Description: Application Load balancer URL


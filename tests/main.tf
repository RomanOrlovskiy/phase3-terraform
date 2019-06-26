####
#### Testing Ansible provisioner for terraform
####

variable "aws_region" {
  description = "AWS region on which we will setup the swarm cluster"
  default = "us-west-2"
}
variable "aws_lab_vpc" {
  description = "Lab_VPC"
  default = "vpc-0e9fb1b78d517dddd"
}
variable "ubuntu_ami" {
  description = "Ubuntu 18.04 Linux AMI"
  default = "ami-005bdb005fb00e791"
}
variable "docker_ubuntu_ami" {
  description = "Docker on ubuntu 18.04"
  default = "ami-02fc91ce0316c43a4"
}
variable "aws_ami" {
  description = "AWS default Linux AMI 2"
  default = "ami-032509850cf9ee54e"
}
variable "instance_type" {
  description = "Instance type"
  default = "t2.micro"
}
variable "key_path" {
  description = "SSH Public Key path"
  default = "~/Downloads/PPKs/WebServer01.pem "
}
variable "key_name" {
  description = "Desired name of Keypair..."
  default = "WebServer01"
}
variable "bootstrap_path" {
  description = "Script to install Docker Engine"
  default = "ubuntu-docker-install.sh"
}
variable "public_vpc_subnet" {
  description = "Public VPC subnet in 10.0.10.0 network"
  default = "subnet-0a49acc8f29b21b15"
}


### security-groups.tf
resource "aws_security_group" "sgswarm" {
  name = "sgswarm"
  vpc_id = "${var.aws_lab_vpc}"
  tags {
        Name = "Lab-SwarmSG"
  }
# Allow all inbound
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Enable ICMP
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

### main.tf
# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_instance" "nginx" {
  ami = "${var.aws_ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  subnet_id = "${var.public_vpc_subnet}"
  vpc_security_group_ids = ["${aws_security_group.sgswarm.id}"]
  tags {
    Name  = "Centos_Nginx"
    role = "frontend-machine"
  }
}

#Provision ASG EC2 instances with Ansible
resource "null_resource" "ecs_hosts" {
  depends_on = ["aws_instance.nginx"]
  
  connection {
    user = "ec2-user"
    private_key = "${file("C:/Users/roman_orlovskyi/ssh/keys/WebServer01.pem")}"
  }
  provisioner "ansible" {
    plays {
      playbook = {
        roles_path = ["C:/Users/roman_orlovskyi/Documents/projects/pre-prod/tf-phase3/modules/ecs_cluster/ansible-data/roles"]
        force_handlers = false
      }
      inventory_file = "C:/Users/roman_orlovskyi/Documents/projects/pre-prod/tf-phase3/modules/ecs_cluster/ansible-data/ec2.py"
      hosts = ["tag_role_frontend-machine"]
    }
  }
}

output "nginx_ip" {
  value = "${aws_instance.nginx.public_ip}"
}
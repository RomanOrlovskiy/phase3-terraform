#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config

yum install -y awslogs jq aws-cli

# Inject the CloudWatch Logs configuration file contents
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/lib/awslogs/agent-state        
 
[/var/log/dmesg]
file = /var/log/dmesg
log_group_name = ${cluster_name}/var/log/dmesg
log_stream_name = {container_instance_id}
[/var/log/messages]
file = /var/log/messages
log_group_name = ${cluster_name}/var/log/messages
log_stream_name = {container_instance_id}
datetime_format = %b %d %H:%M:%S
[/var/log/docker]
file = /var/log/docker
log_group_name = ${cluster_name}/var/log/docker
log_stream_name = {container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%S.%f
[/var/log/ecs/ecs-init.log]
file = /var/log/ecs/ecs-init.log.*
log_group_name = ${cluster_name}/var/log/ecs/ecs-init.log
log_stream_name = {container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
[/var/log/ecs/ecs-agent.log]
file = /var/log/ecs/ecs-agent.log.*
log_group_name = ${cluster_name}/var/log/ecs/ecs-agent.log
log_stream_name = {container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
[/var/log/ecs/audit.log]
file = /var/log/ecs/audit.log.*
log_group_name = ${cluster_name}/var/log/ecs/audit.log
log_stream_name = {container_instance_id}
datetime_format = %Y-%m-%dT%H:%M:%SZ
EOF

# Set the region to send CloudWatch Logs data to (the region where the container instance is located)
region=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
sed -i -e "s/region = .*/region = $region/g" /etc/awslogs/awscli.conf

container_instance_id=$(curl 169.254.169.254/latest/meta-data/instance-id)
sed -i -e "s/{container_instance_id}/$container_instance_id/g" /etc/awslogs/awslogs.conf

sudo service awslogs start
sudo chkconfig awslogs on
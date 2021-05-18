#!/bin/bash
sudo timedatectl set-timezone Asia/Taipei

sudo yum -y install wget
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
sudo rpm -U ./amazon-cloudwatch-agent.rpm
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${cloudwatch_agent_config}

echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config
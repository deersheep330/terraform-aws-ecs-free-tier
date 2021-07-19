# terraform-aws-ecs-free-tier [![CircleCI](https://circleci.com/gh/deersheep330/terraform-aws-ecs-free-tier.svg?style=shield)](https://app.circleci.com/pipelines/github/deersheep330/terraform-aws-ecs-free-tier)

__terraform-aws-ecs-free-tier uses AWS free tier to setup a ready-to-use cloud platform for running any kind of application on it.__
__Since terraform-aws-ecs-free-tier uses AWS free tier, it wouldn't generate any cost.__
It will setup:
- a VPC including subnets, route tables and network acls.
- a MySQL RDS database inside the VPC.
- a ready-to-use ECS cluster with an EC2 free tier instance.
- ECR repositories to host your container images.
- ready-to-use task roles you can directly apply to your task definition.

## How to Use ? 
#### (1) create iam role for terraform cli or terraform cloud: the following roles are required:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1482712489000",
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParameter",
                "ssm:DescribeParameters",
                "ssm:GetParameters",
                "ssm:DeleteParameter",
                "ssm:ListTagsForResource",
                "iam:CreateRole",
                "iam:GetRole",
                "iam:PassRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:GetRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:GetInstanceProfile",
                "iam:CreateInstanceProfile",
                "iam:DeleteInstanceProfile",
                "iam:AddRoleToInstanceProfile",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:CreateServiceLinkedRole",
                "logs:ListTagsLogGroup",
                "logs:DeleteLogGroup",
                "logs:PutRetentionPolicy",
                "elasticache:CreateCacheSubnetGroup",
                "elasticache:CreateCacheCluster",
                "elasticache:AddTagsToResource",
                "elasticache:DescribeCacheSubnetGroups",
                "elasticache:DescribeCacheClusters",
                "elasticache:ListTagsForResource",
                "elasticache:DeleteCacheSubnetGroup",
                "elasticache:DeleteCacheCluster"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```
#### (2) create aws s3 bucket manually then modify the bucket value in main.tf file

#### (3) set variable "ecs_cluster_name". it would be the name of created ecs cluster.

#### (4) set variable "name_prefix". all resources created by terraform would have this name prefix.

#### (5) set variable "ecr_repos". list of ecr repositories to be created.

#### (6) export environment variables
```
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_REGION="us-east-2"
```
#### (7) terraform init => terraform plan => terraform apply

#### (8) the following values would be output: ecs_cluster_id, rds_connection_url, task_role and task_execution_role, you can use them in your application project.
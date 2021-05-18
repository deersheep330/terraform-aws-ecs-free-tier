# terraform-aws-ecs-free-tier

(1) create iam role for terraform cli or terraform cloud: the following roles are required:

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
                "logs:ListTagsLogGroup",
                "logs:DeleteLogGroup"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}

(2) create aws s3 bucket manually then modify the bucket value in main.tf file

(3) change variable "ecs_cluster_name" to the value you want

(4) export environment variables
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_REGION="us-east-2"

(5) terraform init

(6) terraform plan
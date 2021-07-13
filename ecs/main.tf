// [A] iam role for ec2 instance

// [A-1] the policy document to store the policies of the iam role

data "aws_iam_policy_document" "ecs_iam_policy_document" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

// [A-2] iam role

resource "aws_iam_role" "ecs_iam_role" {
  name = "${var.name_prefix}-ecs-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_iam_policy_document.json
}

// [A-3] attach managed ecs policy to the created iam role

resource "aws_iam_role_policy_attachment" "ecs_iam_role_policy_attachment_ecs" {
  role = aws_iam_role.ecs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

// [A-4] attach managed ssm policy to the created role

resource "aws_iam_role_policy_attachment" "ecs_iam_role_policy_attachment_ssm" {
  role = aws_iam_role.ecs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

// [A-5] attach managed cw agent policy to the created role

resource "aws_iam_role_policy_attachment" "ecs_iam_role_policy_attachment_cw_agent" {
  role = aws_iam_role.ecs_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

// [A-6] attach inline ssm policy to the created role

resource "aws_iam_role_policy" "ecs_iam_role_policy_ssm" {
  role = aws_iam_role.ecs_iam_role.name
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

// [A-7] create aws_iam_instance_profile from the created role
// aws_iam_instance_profile is the instance of the create role
// it would be passed to ec2 instances later

resource "aws_iam_instance_profile" "ecs_iam_instance_profile" {
  name = "${var.name_prefix}-ecs-iam-instance-profile"
  role = aws_iam_role.ecs_iam_role.name
  // waiting for others
  // https://stackoverflow.com/questions/36802681/terraform-having-timing-issues-launching-ec2-instance-with-instance-profile
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

// [B] cloudwatch agent for ec2 instance

// [B-1] cloudwatch agent config

data "local_file" "cloudwatch_agent_config_file" {
  filename = "${path.module}/amazon-cloudwatch-agent-lightweight.json"
}

// [B-2] store the cloudwatch config in ssm parameter

resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "cloudwatch-agent-config"
  type  = "String"
  value = data.local_file.cloudwatch_agent_config_file.content
  overwrite = true
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

// [B-3] ec2 instance userdata
// setup cloudwatch agent and register the ec2 instance to ecs cluster

data "template_file" "userdata" {
  template = file("${path.module}/launch-configuration-userdata.sh.tpl")
  vars = {
    cloudwatch_agent_config = aws_ssm_parameter.cloudwatch_agent_config.name
    ecs_cluster_name = var.ecs_cluster_name
  }
}

// [B-4] launch configuration for launching ec2 instances

resource "aws_security_group" "ecs_sg" {

  name = "${var.name_prefix}-ecs-sg"
  vpc_id = var.vpc.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }

  // open ssh port for debug, should be removed later
  
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  // opne 8000 port for demo, should be removed later

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    Name = "${var.name_prefix}-ecs-sg"
  }

}

resource "aws_launch_configuration" "ecs_launch_configuration" {
  name_prefix = var.name_prefix
  image_id = "ami-09f644e1caad2d877"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_iam_instance_profile.id

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [ aws_security_group.ecs_sg.id ]
  associate_public_ip_address = true
  user_data = data.template_file.userdata.rendered

  key_name = "automation-aws"

  depends_on = [ aws_ssm_parameter.cloudwatch_agent_config ]
}

// [B-5] autoscaling group

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name = "${var.name_prefix}-ecs-autoscaling-group"
  vpc_zone_identifier = [ var.subnets[0].id ]
  launch_configuration = aws_launch_configuration.ecs_launch_configuration.name

  desired_capacity = 1
  min_size = 1
  max_size = 1

  tag {
    key = "Name"
    value = "${var.name_prefix}-autoscaled-ec2"
    propagate_at_launch = true
  }

  tag {
    key = "Name"
    value = "${var.name_prefix}-ecs-autoscaling-group"
    propagate_at_launch = false
  }
}

// [B-6] ecs cluster

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_cluster_name
}

// [C] load balancer

// [C-1] application load balancer

data "aws_elb_service_account" "ecs_alb_service_account" {}

resource "aws_s3_bucket" "ecs_alb_log_bucket" {
  bucket = "${var.name_prefix}-ecs-alb-log-bucket"
  acl = "log-delivery-write"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "ecs_alb_log_bucket_policy" {
  bucket = aws_s3_bucket.ecs_alb_log_bucket.id
  policy = data.aws_iam_policy_document.ecs_alb_log_bucket_policy_document.json
}

data "aws_iam_policy_document" "ecs_alb_log_bucket_policy_document" {

  policy_id = "ecs_alb_log_bucket_policy"

  statement {

    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.ecs_alb_log_bucket.arn}/*",
    ]

    principals {
      identifiers = [ data.aws_elb_service_account.ecs_alb_service_account.arn ]
      type = "AWS"
    }
  }

  statement {

    actions = [
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [ "${aws_s3_bucket.ecs_alb_log_bucket.arn}/*" ]

    principals {
      identifiers = [ "delivery.logs.amazonaws.com" ]
      type = "Service"
    }
  }


  statement {

    actions = [
      "s3:GetBucketAcl"
    ]
    effect = "Allow"
    resources = [ "${aws_s3_bucket.ecs_alb_log_bucket.arn}" ]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_alb" "ecs_alb" {
  name = "${var.name_prefix}-ecs-alb"
  security_groups = [ aws_security_group.ecs_sg.id ]
  subnets = "${var.subnets.*.id}"

  access_logs {
    bucket = aws_s3_bucket.ecs_alb_log_bucket.bucket
    prefix = "${var.name_prefix}-ecs-alb"
    enabled = true
  }

  tags = {
    Name = "${var.name_prefix}-ecs-alb"
  }
}

// [C-2] web frontend http 80 target group

resource "aws_alb_target_group" "ecs_alb_target_group" {
  name = "${var.name_prefix}-ecs-alb-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc.id
  stickiness {
    type = "lb_cookie"
  }
  health_check {
    path = "/"
    port = 80
  }
}

resource "aws_autoscaling_attachment" "ecs_alb_autoscaling_attachment" {
  alb_target_group_arn = aws_alb_target_group.ecs_alb_target_group.arn
  autoscaling_group_name = aws_autoscaling_group.ecs_autoscaling_group.id
}

resource "aws_alb_target_group" "ecs_alb_target_group_8080" {
  name = "${var.name_prefix}-target-group-8080"
  port = 8080
  protocol = "HTTP"
  vpc_id = var.vpc.id
  stickiness {
    type = "lb_cookie"
  }
  health_check {
    path = "/health_check"
    port = 8080
  }
}

resource "aws_autoscaling_attachment" "ecs_alb_autoscaling_attachment_8080" {
  alb_target_group_arn = aws_alb_target_group.ecs_alb_target_group_8080.arn
  autoscaling_group_name = aws_autoscaling_group.ecs_autoscaling_group.id
}

resource "aws_alb_listener" "ecs_alb_listener" {
  load_balancer_arn = "${aws_alb.ecs_alb.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.ecs_alb_target_group.arn}"
    type = "forward"
  }
}

resource "aws_alb_listener_rule" "ecs_alb_listener_rule_8080" {
  listener_arn = aws_alb_listener.ecs_alb_listener.arn

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.ecs_alb_target_group_8080.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}


// add https later if we have certificate

// resource "aws_alb_listener" "ecs_https_alb_listener" {
//   load_balancer_arn = "${aws_alb.ecs_alb.arn}"
//   port = "443"
//   protocol = "HTTPS"
//   ssl_policy = "ELBSecurityPolicy-2016-08"
//   certificate_arn = "${var.certificate_arn}"
//   default_action {
//     target_group_arn = "${aws_alb_target_group.ecs_https_alb_target_group.arn}"
//     type = "forward"
//   }
// }

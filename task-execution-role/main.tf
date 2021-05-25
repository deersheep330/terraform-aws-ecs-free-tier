// [1] create task role for task definition

data "aws_iam_policy_document" "task_role_iam_policy_document" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "ecs-tasks.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "task_role_iam_role" {
  name = "${var.name_prefix}-task-role-iam-role"
  assume_role_policy = data.aws_iam_policy_document.task_role_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_role_iam_role_policy_attachment" {
  role = aws_iam_role.task_role_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// [2] create task execution role for task definition

data "aws_iam_policy_document" "task_execution_role_iam_policy_document" {
  statement {
    actions = [ "sts:AssumeRole" ]
    principals {
      type = "Service"
      identifiers = [ "ecs-tasks.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "task_execution_role_iam_role" {
  name = "${var.name_prefix}-task-execution-role-iam-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_role_iam_policy_document.json
}

resource "aws_iam_role_policy_attachment" "task_execution_role_iam_role_policy_attachment" {
  role = aws_iam_role.task_execution_role_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "app" {
  statement {
    actions   = ["s3:Get*",
                 "s3:List*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_execution_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ecr" {
  name = "AWSAppRunnerServicePolicyForECRAccess"
}

resource "aws_iam_role" "app_execution_role" {
  name = "app_execution_role"
  description = "ECS execution role with access to private ECR repositories"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "app_ecs_default" {
  role = aws_iam_role.app_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_ecr" {
  role = aws_iam_role.app_execution_role.name
  policy_arn = data.aws_iam_policy.ecr.arn
}

resource "aws_iam_role" "app_task_role" {
  name = "app_task_role"
  description = "ECS task role with access to S3 for app"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  inline_policy {
    name = "s3"
    policy = data.aws_iam_policy_document.app.json
  }
}

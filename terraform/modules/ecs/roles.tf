data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_secrets" {
  statement {
    actions = ["ssm:GetParameters"]
    resources = [
      "${aws_ssm_parameter.api_token.arn}",
      "${aws_ssm_parameter.db_pass.arn}",
      "${aws_ssm_parameter.telegram_token.arn}"
    ]
  }
}

data "aws_iam_policy" "ecs_execution_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ecr" {
  name = "AWSAppRunnerServicePolicyForECRAccess"
}

data "aws_iam_policy" "logs" {
  name = "CloudWatchLogsFullAccess"
}


resource "aws_iam_role" "app_execution_role" {
  name               = "app_execution_role-${var.app_name}-${var.env}"
  description        = "ECS execution role with access to private ECR repositories"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

  inline_policy {
    name   = "secrets"
    policy = data.aws_iam_policy_document.ecs_secrets.json
  }
}

resource "aws_iam_role_policy_attachment" "app_ecs_default" {
  role       = aws_iam_role.app_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_execution_policy.arn
}

resource "aws_iam_role_policy_attachment" "app_ecr" {
  role       = aws_iam_role.app_execution_role.name
  policy_arn = data.aws_iam_policy.ecr.arn
}

resource "aws_iam_role_policy_attachment" "app_logs" {
  role       = aws_iam_role.app_execution_role.name
  policy_arn = data.aws_iam_policy.logs.arn
}

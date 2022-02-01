#data "aws_iam_policy_document" "app" {
#  statement {
#    actions   = ["s3:Get*",
#                 "s3:List*"]
#    resources = ["*"]
#  }
#}

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
    resources = ["${aws_ssm_parameter.db_pass.arn}",
    "${aws_ssm_parameter.telegram_token.arn}"]
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_service" {
  statement {
    actions = ["logs:CreateLogGroup",
      "logs:CreateLogStream",
    "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/auto_search_bot",
    "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/auto_search_bot:*"]
  }

  statement {
    actions = ["s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
    "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::codepipeline-${data.aws_region.current.name}-*"]
  }

  statement {
    actions = ["codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutCodeCoverages",
    "codebuild:BatchPutTestCases"]
    resources = ["arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/auto_search_bot-*"]
  }

  statement {
    actions = ["ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
    "ecr:PutImage"]
    resources = ["*"]
  }

  statement {
    actions = ["ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
    "ec2:DescribeVpcs"]

    resources = ["*"]
  }

  statement {
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values   = [for subnet in aws_subnet.priv : subnet.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_execution_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ecr" {
  name = "AWSAppRunnerServicePolicyForECRAccess"
}

data "aws_iam_policy" "container_images" {
  name = "EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

data "aws_iam_policy" "logs" {
  name = "CloudWatchLogsFullAccess"
}

resource "aws_iam_role" "app_execution_role" {
  name               = "app_execution_role"
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

resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role"
  description        = "CodeBuild service role with container image build and upload permissions"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json

  inline_policy {
    name   = "codebuild"
    policy = data.aws_iam_policy_document.codebuild_service.json
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_logs" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = data.aws_iam_policy.logs.arn
}

#resource "aws_iam_role" "app_task_role" {
#  name = "app_task_role"
#  description = "ECS task role with access to S3 for app"
#  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json

#  inline_policy {
#    name = "s3"
#    policy = data.aws_iam_policy_document.app.json
#  }
#}

data "aws_subnet" "priv" {
  count = length(var.priv_ids)
  id    = var.priv_ids[count.index]
}

data "aws_ecs_cluster" "app" {
  cluster_name = var.ecs_cluster_name
}

data "aws_ecs_service" "app" {
  service_name = var.ecs_service_name
  cluster_arn  = data.aws_ecs_cluster.app.arn
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
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.codebuild.name}",
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.codebuild.name}:*"
    ]
  }

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = ["arn:aws:s3:::codepipeline-${var.aws_region}-*"]
  }

  statement {
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutCodeCoverages",
      "codebuild:BatchPutTestCases"
    ]

    resources = ["arn:aws:codebuild:${var.aws_region}:${local.account_id}:report-group/${var.app_name}-*"]
  }

  statement {
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs"
    ]

    resources = ["*"]
  }

  statement {
    actions   = ["ec2:CreateNetworkInterfacePermission"]
    resources = ["arn:aws:ec2:${var.aws_region}:${local.account_id}:network-interface/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Subnet"
      values   = [for subnet in data.aws_subnet.priv : subnet.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values   = ["codebuild.amazonaws.com"]
    }
  }

  statement {
    actions   = ["ecs:UpdateService"]
    resources = [data.aws_ecs_service.app.arn]
  }
}

data "aws_iam_policy" "container_images" {
  name = "EC2InstanceProfileForImageBuilderECRContainerBuilds"
}

data "aws_iam_policy" "logs" {
  name = "CloudWatchLogsFullAccess"
}


resource "aws_iam_role" "codebuild_role" {
  name               = "codebuild_role-${var.app_name}-${var.env}"
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

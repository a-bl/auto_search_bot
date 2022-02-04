data "github_repository" "app" {
  full_name = var.github_repo_full_name
}

resource "aws_codebuild_source_credential" "github" {
  server_type = "GITHUB"
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  token       = var.github_token
}

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.app_name}/${var.env}"
  retention_in_days = 0
}

resource "aws_cloudwatch_log_stream" "codebuild" {
  name           = "/aws/codebuild/${var.app_name}/${var.env}/stream"
  log_group_name = aws_cloudwatch_log_group.codebuild.name
}

resource "aws_codebuild_project" "app" {
  name          = "${var.app_name}-${var.env}"
  service_role  = aws_iam_role.codebuild_role.arn
  badge_enabled = true

  source {
    type            = "GITHUB"
    location        = data.github_repository.app.http_clone_url
    git_clone_depth = 1
    buildspec       = "terraform/buildspec.yml"
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    type            = "LINUX_CONTAINER"
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    privileged_mode = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.ecr_name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "ECS_SERVICE_NAME"
      value = var.ecs_service_name
    }

    environment_variable {
      name  = "ECS_CLUSTER_NAME"
      value = var.ecs_cluster_name
    }
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  vpc_config {
    vpc_id             = var.vpc_id
    subnets            = var.priv_ids
    security_group_ids = [var.sg_id]
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.codebuild.name
      stream_name = aws_cloudwatch_log_stream.codebuild.name
    }
  }
}

resource "aws_codebuild_webhook" "github" {
  project_name = aws_codebuild_project.app.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "EVENT"
      pattern = "PULL_REQUEST_MERGED"
    }
  }
}

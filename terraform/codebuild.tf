data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "github_repository" "app" {
  full_name = "a-bl/auto_search_bot"
}

resource "aws_codebuild_source_credential" "github" {
  server_type = "GITHUB"
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  token       = var.github_token
}

resource "aws_codebuild_project" "app" {
  name          = "auto_search_bot"
  service_role  = aws_iam_role.codebuild_role.arn
  badge_enabled = true

  source {
    type            = "GITHUB"
    location        = "https://github.com/a-bl/auto_search_bot.git"
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
      value = data.aws_region.current.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.repo.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
  }

  #vpc_config {
  #  vpc_id             = aws_vpc.main.id
  #  subnets            = [for subnet in aws_subnet.priv : subnet.id]
  #  security_group_ids = [aws_default_security_group.app.id]
  #}
}

resource "aws_codebuild_webhook" "github" {
  project_name = aws_codebuild_project.app.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }
  }
}

resource "github_repository_file" "readme" {
  repository    = data.github_repository.app.name
  file          = "README.md"
  content       = templatefile("README.md.tpl", { badge_url = aws_codebuild_project.app.badge_url })
  commit_author = "hashicorp"
  commit_email  = "hello@hashicorp.com"
  depends_on    = [aws_codebuild_webhook.github]
}

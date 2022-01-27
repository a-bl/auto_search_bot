resource "aws_ecs_task_definition" "app" {
  family                   = "auto_search_bot"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution_role.arn
  depends_on               = [aws_iam_role_policy_attachment.app_ecr]
  container_definitions    = jsonencode([
    {
      name         = "auto_search_bot"
      image        = "${aws_ecr_repository.repo.repository_url}:latest"
      essential    = true
      memory       = 256
      secrets      = {
        name      = "TOKEN"
        valueFrom = aws_ssm_parameter.telegram_token.arn
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_cluster" "app" {
  name = "auto_search_bot"
}

resource "aws_ecs_service" "app" {
  name                = "auto_search_bot"
  cluster             = aws_ecs_cluster.app.id
  task_definition     = aws_ecs_task_definition.app.arn
  scheduling_strategy = "DAEMON"

  network_configuration {
    subnets         = [for subnet in aws_subnet.priv : subnet.id]
    security_groups = [aws_security_group.app.id]
  }

  ordered_placement_strategy {
    type = "random"
  }

  placement_constraints {
    type = "memberOf"
    expression = "runningTasksCount == 1"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "auto_search_bot"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution_role.arn
  depends_on               = [aws_iam_role_policy_attachment.app_ecr]
  container_definitions = jsonencode([
    {
      name   = "auto_search_bot_scraper"
      image  = "${aws_ecr_repository.repo.repository_url}:latest"
      memory = 256

      environment = [
        {
          name  = "SCRIPT"
          value = "scraper.py"
        },
        {
          name  = "PG_HOST"
          value = "${aws_db_instance.main.address}"
        },
        {
          name  = "PG_PORT"
          value = "${aws_db_instance.main.port}"
        },
        {
          name  = "PG_USER"
          value = "${random_pet.db_user.id}"
        },
        {
          name  = "PG_DB"
          value = "telegram_bot_db"
        }
      ]

      secrets = [
        {
          name      = "TOKEN"
          valueFrom = "${aws_ssm_parameter.telegram_token.arn}"
        },
        {
          name      = "PG_PASS"
          valueFrom = "${aws_ssm_parameter.db_pass.arn}"
        }
      ]
    },
    {
      name      = "auto_search_bot"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true
      memory    = 256

      dependsOn = [
        {
          containerName = "auto_search_bot_scraper"
          condition     = "SUCCESS"
        }
      ]

      environment = [
        {
          name  = "SCRIPT"
          value = "bot.py"
        },
        {
          name  = "PG_HOST"
          value = "${aws_db_instance.main.address}"
        },
        {
          name  = "PG_PORT"
          value = "${aws_db_instance.main.port}"
        },
        {
          name  = "PG_USER"
          value = "${random_pet.db_user.id}"
        },
        {
          name  = "PG_DB"
          value = "telegram_bot_db"
        }
      ]

      secrets = [
        {
          name      = "TOKEN"
          valueFrom = "${aws_ssm_parameter.telegram_token.arn}"
        },
        {
          name      = "PG_PASS"
          valueFrom = "${aws_ssm_parameter.db_pass.arn}"
        }
      ]
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
    subnets         = [for subnet in aws_subnet.pub : subnet.id]
  }

  ordered_placement_strategy {
    type = "random"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "runningTasksCount == 1"
  }
}

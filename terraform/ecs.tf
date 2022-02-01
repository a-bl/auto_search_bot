resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.app_name}/bot"
  retention_in_days = 0
}

resource "aws_cloudwatch_log_group" "app_scraper" {
  name              = "/aws/ecs/${var.app_name}/scraper"
  retention_in_days = 0
}

resource "aws_ecs_task_definition" "app" {
  family                   = "auto_search_bot"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution_role.arn
  depends_on               = [aws_iam_role_policy_attachment.app_ecr]

  container_definitions = jsonencode([
    {
      name      = "auto_search_bot_scraper"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = false

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
          value = "${tostring(aws_db_instance.main.port)}"
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

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-group         = "${aws_cloudwatch_log_group.app_scraper.name}"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "auto_search_bot"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true

      dependsOn = [
        {
          containerName = "auto_search_bot_scraper"
          condition     = "START"
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
          value = "${tostring(aws_db_instance.main.port)}"
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

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-group         = "${aws_cloudwatch_log_group.app.name}"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

resource "aws_ecs_cluster" "app" {
  name               = "auto_search_bot"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_service" "app" {
  name            = "auto_search_bot"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  #scheduling_strategy = "DAEMON"

  network_configuration {
    subnets          = [for subnet in aws_subnet.pub : subnet.id]
    security_groups  = [aws_default_security_group.app.id]
    assign_public_ip = true
  }
}

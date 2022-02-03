resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.app_name}/${var.env}/bot"
  retention_in_days = 0
}

resource "aws_cloudwatch_log_group" "app_scraper" {
  name              = "/aws/ecs/${var.app_name}/${var.env}/scraper"
  retention_in_days = 0
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.app_name}-${var.env}"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.app_execution_role.arn
  depends_on               = [aws_iam_role_policy_attachment.app_ecr]

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}_scraper"
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
          value = "${tostring(var.db_port)}"
        },
        {
          name  = "PG_USER"
          value = "${random_pet.db_user.id}"
        },
        {
          name  = "PG_DB"
          value = "${var.db_name}"
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
        },
        {
          name      = "API_TOKEN"
          valueFrom = "${aws_ssm_parameter.api_token.arn}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "${var.aws_region}"
          awslogs-group         = "${aws_cloudwatch_log_group.app_scraper.name}"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "${var.app_name}"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true

      dependsOn = [
        {
          containerName = "${var.app_name}_scraper"
          condition     = "START"
        }
      ]

      environment = [
        {
          name  = "PG_HOST"
          value = "${aws_db_instance.main.address}"
        },
        {
          name  = "PG_PORT"
          value = "${tostring(var.db_port)}"
        },
        {
          name  = "PG_USER"
          value = "${random_pet.db_user.id}"
        },
        {
          name  = "PG_DB"
          value = "${var.db_name}"
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
        },
        {
          name      = "API_TOKEN"
          valueFrom = "${aws_ssm_parameter.api_token.arn}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = "${var.aws_region}"
          awslogs-group         = "${aws_cloudwatch_log_group.app.name}"
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
  name               = "${var.app_name}-${var.env}"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-${var.env}"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = var.priv_ids
    security_groups = [var.sg_id]
  }
}

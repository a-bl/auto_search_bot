resource "aws_ecs_task_definition" "app" {
  family                   = "app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.app_execution_role.arn
  task_role_arn            = aws_iam_role.app_task_role.arn
  container_definitions    = jsonencode([
    {
      name         = "app"
      image        = "${aws_ecr_repository.repo.repository_url}:latest"
      essential    = true
      portMappings = [
        {
          containerPort = 80
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
  name = "app"
  capacity_providers = ["FARGATE"]
}

resource "aws_ecs_service" "app" {
  name            = "app"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = length(var.avail_zones)
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [for subnet in aws_subnet.priv : subnet.id]
    security_groups = [aws_security_group.demo.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.test.arn
    container_name   = "app"
    container_port   = 80
  }
}

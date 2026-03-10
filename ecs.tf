resource "aws_cloudwatch_log_group" "atlantis" {
  name              = "/ecs/${local.name}"
  retention_in_days = 30

  tags = local.merged_tags
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"

  tags = local.merged_tags
}

resource "aws_lb" "this" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = values(aws_subnet.public)[*].id

  tags = local.merged_tags
}

resource "aws_lb_target_group" "atlantis" {
  name        = "${local.name}-tg"
  port        = var.atlantis_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id

  health_check {
    enabled             = true
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
    path                = "/healthz"
  }

  tags = local.merged_tags
}

resource "aws_lb_listener" "http_plain" {
  count = var.acm_certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.atlantis.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.acm_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.atlantis.arn
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.atlantis_iac_role.arn

  container_definitions = jsonencode([
    {
      name      = "atlantis"
      image     = var.atlantis_container_image
      essential = true
      command   = ["server"]

      portMappings = [
        {
          containerPort = var.atlantis_port
          hostPort      = var.atlantis_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ATLANTIS_PORT"
          value = tostring(var.atlantis_port)
        },
        {
          name  = "ATLANTIS_ATLANTIS_URL"
          value = local.atlantis_url
        },
        {
          name  = "ATLANTIS_REPO_ALLOWLIST"
          value = var.atlantis_repo_allowlist
        },
        {
          name  = "ATLANTIS_GH_USER"
          value = var.github_user
        },
        {
          name  = "ATLANTIS_ALLOW_FORK_PRS"
          value = "false"
        },
        {
          name  = "ATLANTIS_DISABLE_APPLY_ALL"
          value = "true"
        },
        {
          name  = "ATLANTIS_AUTOMERGE"
          value = "false"
        },
        {
          name  = "ATLANTIS_WRITE_GIT_CREDS"
          value = "true"
        },
        {
          name  = "ATLANTIS_HIDE_PREV_PLAN_COMMENTS"
          value = "true"
        }
      ]

      secrets = [
        {
          name      = "ATLANTIS_GH_TOKEN"
          valueFrom = var.github_token_secret_arn
        },
        {
          name      = "ATLANTIS_GH_WEBHOOK_SECRET"
          valueFrom = var.github_webhook_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.atlantis.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "atlantis"
        }
      }
    }
  ])

  tags = local.merged_tags
}

resource "aws_ecs_service" "this" {
  name            = "${local.name}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.atlantis.arn
    container_name   = "atlantis"
    container_port   = var.atlantis_port
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.atlantis.id]
    subnets          = values(aws_subnet.public)[*].id
  }

  depends_on = [
    aws_lb_listener.http_plain,
    aws_lb_listener.http_redirect,
    aws_lb_listener.https
  ]

  tags = local.merged_tags
}



resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Permite trafego para o ALB do Atlantis."
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  dynamic "ingress" {
    for_each = var.acm_certificate_arn != "" ? [1] : []

    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.merged_tags, {
    Name = "${local.name}-alb-sg"
  })
}

resource "aws_security_group" "atlantis" {
  name        = "${local.name}-task-sg"
  description = "Permite trafego do ALB para a task do Atlantis."
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = var.atlantis_port
    to_port         = var.atlantis_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.merged_tags, {
    Name = "${local.name}-task-sg"
  })
}



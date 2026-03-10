variable "aws_region" {
  description = "Regiao AWS para deploy da stack."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefixo de nomes dos recursos."
  type        = string
  default     = "atlantis"
}

variable "vpc_cidr" {
  description = "CIDR da VPC."
  type        = string
  default     = "10.80.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDRs das sub-redes publicas usadas pelo ALB/ECS."
  type        = list(string)
  default     = ["10.80.1.0/24", "10.80.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "Informe ao menos duas sub-redes publicas para alta disponibilidade."
  }
}

variable "allowed_cidr_blocks" {
  description = "CIDRs permitidos para acesso ao ALB do Atlantis."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "acm_certificate_arn" {
  description = "ARN do certificado ACM para HTTPS no ALB (opcional)."
  type        = string
  default     = ""
}

variable "atlantis_url" {
  description = "URL publica do Atlantis. Se vazio, usa DNS do ALB."
  type        = string
  default     = ""
}

variable "atlantis_container_image" {
  description = "Imagem do container Atlantis."
  type        = string
  default     = "ghcr.io/runatlantis/atlantis:v0.32.0"
}

variable "atlantis_port" {
  description = "Porta interna do Atlantis."
  type        = number
  default     = 4141
}

variable "task_cpu" {
  description = "CPU da task Fargate."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memoria (MiB) da task Fargate."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Quantidade de tasks Atlantis."
  type        = number
  default     = 1
}

variable "atlantis_repo_allowlist" {
  description = "Allowlist de repositorios GitHub (ex: github.com/minha-org/*)."
  type        = string
}

variable "github_user" {
  description = "Usuario bot do GitHub usado pelo Atlantis."
  type        = string
}

variable "github_token_secret_arn" {
  description = "ARN do secret no Secrets Manager contendo o token GitHub."
  type        = string
}

variable "github_webhook_secret_arn" {
  description = "ARN do secret no Secrets Manager contendo o webhook secret."
  type        = string
}

variable "enable_iam_guardrail_policy" {
  description = "Cria politica IAM de guardrail para negar mutacoes fora do Atlantis."
  type        = bool
  default     = true
}

variable "guardrail_role_names" {
  description = "Roles IAM que receberao a politica de negacao."
  type        = list(string)
  default     = []
}

variable "guardrail_user_names" {
  description = "Users IAM que receberao a politica de negacao."
  type        = list(string)
  default     = []
}

variable "guardrail_group_names" {
  description = "Groups IAM que receberao a politica de negacao."
  type        = list(string)
  default     = []
}

variable "enable_only_atlantis_scp" {
  description = "Ativa SCP para bloquear mudancas de infraestrutura fora do Atlantis."
  type        = bool
  default     = false
}

variable "organization_target_id" {
  description = "ID da conta ou OU que recebera a SCP (ex: 123456789012 ou ou-xxxx-yyyyyyyy)."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_only_atlantis_scp || var.organization_target_id != ""
    error_message = "organization_target_id e obrigatorio quando enable_only_atlantis_scp=true."
  }
}

variable "break_glass_principal_arns" {
  description = "Principais adicionais autorizados a mutar infra (uso emergencial)."
  type        = list(string)
  default     = []
}

variable "guardrail_mutating_actions" {
  description = "Acoes consideradas mutacao de infraestrutura para os bloqueios."
  type        = list(string)
  default = [
    "acm:Delete*",
    "acm:Import*",
    "acm:Request*",
    "apigateway:DELETE",
    "apigateway:PATCH",
    "apigateway:POST",
    "apigateway:PUT",
    "application-autoscaling:Delete*",
    "application-autoscaling:Deregister*",
    "application-autoscaling:Put*",
    "application-autoscaling:Register*",
    "autoscaling:Attach*",
    "autoscaling:Complete*",
    "autoscaling:Create*",
    "autoscaling:Delete*",
    "autoscaling:Detach*",
    "autoscaling:Disable*",
    "autoscaling:Enable*",
    "autoscaling:Put*",
    "autoscaling:Set*",
    "autoscaling:Start*",
    "autoscaling:Terminate*",
    "autoscaling:Update*",
    "cloudformation:Create*",
    "cloudformation:Delete*",
    "cloudformation:Execute*",
    "cloudformation:Set*",
    "cloudformation:Update*",
    "cloudfront:Create*",
    "cloudfront:Delete*",
    "cloudfront:Update*",
    "cloudtrail:Create*",
    "cloudtrail:Delete*",
    "cloudtrail:Put*",
    "cloudtrail:Start*",
    "cloudtrail:Stop*",
    "cloudtrail:Update*",
    "cloudwatch:Delete*",
    "cloudwatch:Put*",
    "cloudwatch:Set*",
    "cloudwatch:Start*",
    "cloudwatch:Stop*",
    "dynamodb:Create*",
    "dynamodb:Delete*",
    "dynamodb:TagResource",
    "dynamodb:UntagResource",
    "dynamodb:Update*",
    "ec2:Associate*",
    "ec2:Attach*",
    "ec2:Create*",
    "ec2:Delete*",
    "ec2:Detach*",
    "ec2:Disassociate*",
    "ec2:Modify*",
    "ec2:Reboot*",
    "ec2:Replace*",
    "ec2:Run*",
    "ec2:Start*",
    "ec2:Stop*",
    "ec2:Terminate*",
    "ecr:Create*",
    "ecr:Delete*",
    "ecr:Put*",
    "ecr:Set*",
    "ecr:TagResource",
    "ecr:UntagResource",
    "ecs:Create*",
    "ecs:Delete*",
    "ecs:Deregister*",
    "ecs:Put*",
    "ecs:Register*",
    "ecs:RunTask",
    "ecs:StartTask",
    "ecs:StopTask",
    "ecs:TagResource",
    "ecs:UntagResource",
    "ecs:Update*",
    "eks:Associate*",
    "eks:Create*",
    "eks:Delete*",
    "eks:Disassociate*",
    "eks:TagResource",
    "eks:UntagResource",
    "eks:Update*",
    "elasticloadbalancing:Add*",
    "elasticloadbalancing:Create*",
    "elasticloadbalancing:Delete*",
    "elasticloadbalancing:Deregister*",
    "elasticloadbalancing:Modify*",
    "elasticloadbalancing:Register*",
    "elasticloadbalancing:Remove*",
    "elasticloadbalancing:Set*",
    "events:Delete*",
    "events:Disable*",
    "events:Enable*",
    "events:Put*",
    "events:Remove*",
    "events:TagResource",
    "events:UntagResource",
    "iam:Add*",
    "iam:Attach*",
    "iam:Create*",
    "iam:Delete*",
    "iam:Detach*",
    "iam:PassRole",
    "iam:Put*",
    "iam:Remove*",
    "iam:Set*",
    "iam:Tag*",
    "iam:Untag*",
    "iam:Update*",
    "kms:CancelKeyDeletion",
    "kms:Create*",
    "kms:Delete*",
    "kms:Disable*",
    "kms:Enable*",
    "kms:Put*",
    "kms:ScheduleKeyDeletion",
    "kms:TagResource",
    "kms:UntagResource",
    "kms:Update*",
    "lambda:Add*",
    "lambda:Create*",
    "lambda:Delete*",
    "lambda:Put*",
    "lambda:Remove*",
    "lambda:TagResource",
    "lambda:UntagResource",
    "lambda:Update*",
    "logs:Associate*",
    "logs:Create*",
    "logs:Delete*",
    "logs:Disassociate*",
    "logs:Put*",
    "logs:TagResource",
    "logs:UntagResource",
    "rds:Add*",
    "rds:Create*",
    "rds:Delete*",
    "rds:Modify*",
    "rds:Promote*",
    "rds:Reboot*",
    "rds:Remove*",
    "rds:Restore*",
    "rds:Start*",
    "rds:Stop*",
    "rds:TagResource",
    "rds:UntagResource",
    "route53:Associate*",
    "route53:Change*",
    "route53:Create*",
    "route53:Delete*",
    "route53:Disassociate*",
    "route53:Update*",
    "s3:Create*",
    "s3:Delete*",
    "s3:Put*",
    "secretsmanager:Create*",
    "secretsmanager:Delete*",
    "secretsmanager:Put*",
    "secretsmanager:Rotate*",
    "secretsmanager:TagResource",
    "secretsmanager:UntagResource",
    "secretsmanager:Update*",
    "sns:Create*",
    "sns:Delete*",
    "sns:Set*",
    "sns:Subscribe",
    "sns:TagResource",
    "sns:Unsubscribe",
    "sns:UntagResource",
    "sqs:Create*",
    "sqs:Delete*",
    "sqs:Set*",
    "sqs:TagQueue",
    "sqs:UntagQueue",
    "ssm:Add*",
    "ssm:Create*",
    "ssm:Delete*",
    "ssm:Deregister*",
    "ssm:Label*",
    "ssm:Put*",
    "ssm:Remove*",
    "ssm:Start*",
    "ssm:Stop*",
    "ssm:Update*",
    "wafv2:Associate*",
    "wafv2:Create*",
    "wafv2:Delete*",
    "wafv2:Disassociate*",
    "wafv2:Put*",
    "wafv2:TagResource",
    "wafv2:UntagResource",
    "wafv2:Update*"
  ]
}

variable "tags" {
  description = "Tags adicionais para todos os recursos."
  type        = map(string)
  default     = {}
}



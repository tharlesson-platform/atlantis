data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "${local.name}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_base" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_execution_secrets" {
  statement {
    sid    = "ReadGithubSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      var.github_token_secret_arn,
      var.github_webhook_secret_arn
    ]
  }

  statement {
    sid    = "DecryptSecretsIfKms"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name   = "${local.name}-ecs-secrets-policy"
  role   = aws_iam_role.ecs_execution_role.id
  policy = data.aws_iam_policy_document.ecs_execution_secrets.json
}

resource "aws_iam_role" "atlantis_iac_role" {
  name               = "${local.name}-iac-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "atlantis_iac_admin" {
  role       = aws_iam_role.atlantis_iac_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "non_atlantis_guardrail" {
  statement {
    sid       = "DenyInfraMutationsOutsideAtlantis"
    effect    = "Deny"
    actions   = var.guardrail_mutating_actions
    resources = ["*"]

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = local.allowed_guardrail_principal_arns
    }

    condition {
      test     = "BoolIfExists"
      variable = "aws:PrincipalIsAWSService"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "non_atlantis_guardrail" {
  count = var.enable_iam_guardrail_policy ? 1 : 0

  name        = "${local.name}-deny-non-atlantis-mutations"
  description = "Nega mutacoes de infraestrutura fora do principal do Atlantis."
  policy      = data.aws_iam_policy_document.non_atlantis_guardrail.json

  tags = local.merged_tags
}

resource "aws_iam_role_policy_attachment" "guardrail_roles" {
  for_each = var.enable_iam_guardrail_policy ? toset(var.guardrail_role_names) : toset([])

  role       = each.value
  policy_arn = aws_iam_policy.non_atlantis_guardrail[0].arn
}

resource "aws_iam_user_policy_attachment" "guardrail_users" {
  for_each = var.enable_iam_guardrail_policy ? toset(var.guardrail_user_names) : toset([])

  user       = each.value
  policy_arn = aws_iam_policy.non_atlantis_guardrail[0].arn
}

resource "aws_iam_group_policy_attachment" "guardrail_groups" {
  for_each = var.enable_iam_guardrail_policy ? toset(var.guardrail_group_names) : toset([])

  group      = each.value
  policy_arn = aws_iam_policy.non_atlantis_guardrail[0].arn
}

resource "aws_organizations_policy" "only_atlantis" {
  count = var.enable_only_atlantis_scp ? 1 : 0

  name        = "${local.name}-only-atlantis-scp"
  description = "Bloqueia mutacoes de infra fora do principal do Atlantis."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.non_atlantis_guardrail.json

  tags = local.merged_tags
}

resource "aws_organizations_policy_attachment" "only_atlantis" {
  count = var.enable_only_atlantis_scp ? 1 : 0

  policy_id = aws_organizations_policy.only_atlantis[0].id
  target_id = var.organization_target_id
}



output "atlantis_url" {
  description = "URL do Atlantis."
  value       = local.atlantis_url
}

output "github_webhook_url" {
  description = "Endpoint do webhook GitHub."
  value       = "${local.atlantis_url}/events"
}

output "atlantis_iac_role_arn" {
  description = "Role IAM usada pelo Atlantis para aplicar infraestrutura."
  value       = aws_iam_role.atlantis_iac_role.arn
}

output "guardrail_policy_arn" {
  description = "ARN da policy IAM de bloqueio fora do Atlantis (se habilitada)."
  value       = try(aws_iam_policy.non_atlantis_guardrail[0].arn, null)
}

output "scp_policy_id" {
  description = "ID da SCP de bloqueio fora do Atlantis (se habilitada)."
  value       = try(aws_organizations_policy.only_atlantis[0].id, null)
}



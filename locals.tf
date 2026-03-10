data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = var.name_prefix

  merged_tags = merge(
    {
      Project   = "atlantis"
      ManagedBy = "terraform"
    },
    var.tags
  )

  atlantis_url = var.atlantis_url != "" ? var.atlantis_url : format(
    "%s://%s",
    var.acm_certificate_arn != "" ? "https" : "http",
    aws_lb.this.dns_name
  )

  break_glass_principal_arns = distinct(compact(concat(
    var.break_glass_principal_arns,
    var.enable_only_atlantis_scp ? ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"] : []
  )))

  allowed_guardrail_principal_arns = distinct(concat(
    [aws_iam_role.atlantis_iac_role.arn],
    local.break_glass_principal_arns
  ))

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs : idx => {
      cidr = cidr
      az   = data.aws_availability_zones.available.names[idx]
    }
  }
}



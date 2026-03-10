# Stack Atlantis + GitHub + AWS

Esta stack cria um ambiente de Atlantis em AWS (ECS Fargate), integrado com GitHub, e prepara uma role IAM para centralizar toda a execucao de IaC pela propria instancia do Atlantis.

## O que a stack provisiona

- VPC com sub-redes publicas para o servico.
- ALB para receber webhooks do GitHub e acesso ao Atlantis.
- ECS Cluster + Service (Fargate) com container oficial do Atlantis.
- Role IAM de execucao do Atlantis (`atlantis_iac_role`) com permissao administrativa para aplicar IaC.
- Guardrail para bloquear mutacoes de infraestrutura fora do principal do Atlantis:
  - Politica IAM de negacao (anexavel a usuarios/roles/grupos).
  - SCP opcional (AWS Organizations) para enforcement em nivel de conta/OU.

## Pre-requisitos

1. Terraform `>= 1.6`.
1. AWS credentials com permissao para criar VPC, ECS, ALB, IAM e (opcionalmente) Organizations.
1. Secret no AWS Secrets Manager com o token do GitHub App/usuario bot.
1. Secret no AWS Secrets Manager com o webhook secret do Atlantis.
1. Repositorios GitHub com arquivo `atlantis.yaml` (exemplo em `examples/atlantis.yaml`).

## Como usar

1. Copie o exemplo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

1. Ajuste variaveis obrigatorias em `terraform.tfvars`:

- `atlantis_repo_allowlist`
- `github_user`
- `github_token_secret_arn`
- `github_webhook_secret_arn`

1. Inicialize e aplique:

```bash
terraform init
terraform plan
terraform apply
```

1. Configure o webhook em cada repositorio GitHub:

- URL: `https://<SEU_ATLANTIS>/events` (ou output `github_webhook_url`)
- Content type: `application/json`
- Secret: mesmo valor do secret configurado em `github_webhook_secret_arn`
- Eventos: Pull requests, Issue comments, Pull request reviews, Push

## Bloquear mudancas fora do Atlantis

### Opcao A: Politica IAM (conta sem Organizations)

- Habilite `enable_iam_guardrail_policy = true`.
- Informe `guardrail_role_names`, `guardrail_user_names` e/ou `guardrail_group_names`.
- A politica nega acoes de mutacao de infra quando o principal nao for a role do Atlantis (ou break-glass).

### Opcao B: SCP (enforcement forte via Organizations)

- Habilite `enable_only_atlantis_scp = true`.
- Preencha `organization_target_id` (ID da conta ou OU).
- Recomenda-se configurar `break_glass_principal_arns` para recuperacao de emergencia.

## Outputs importantes

- `atlantis_url`: URL final para acessar o Atlantis.
- `github_webhook_url`: endpoint para webhook GitHub.
- `atlantis_iac_role_arn`: principal autorizado para aplicar IaC.



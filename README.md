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

## Exemplos de `atlantis.yaml`

O repositorio agora inclui tres referencias praticas em `examples/`:

- `examples/atlantis.yaml`: exemplo minimo para um unico projeto Terraform.
- `examples/atlantis.monorepo.yaml`: modelo para mono-repo com multiplos diretorios e `autoplan` seletivo.
- `examples/atlantis.multi-stack.yaml`: modelo para multiplos ambientes com requisitos extras de `apply` em producao.

## Validacao automatizada

Foi adicionada uma pipeline de CI para:

- `terraform fmt -check -recursive`;
- `terraform init -backend=false` e `terraform validate` da stack raiz;
- verificacao da presenca dos exemplos de `atlantis.yaml`.

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

## Licenca

Este projeto esta licenciado sob a Apache License 2.0. Consulte o arquivo `LICENSE` para mais detalhes.

## Atribuicao

Este projeto foi desenvolvido e publicado por **Tharlesson**.
Caso voce utilize este material como base em ambientes internos, estudos, adaptacoes ou redistribuicoes, preserve os creditos de autoria e os avisos de licenca aplicaveis.

## Creditos e Uso

Este repositorio foi criado com foco em automacao, padronizacao operacional e melhoria da rotina de profissionais de SRE, DevOps, Cloud e Plataforma.

Voce pode:
- estudar
- reutilizar
- adaptar
- evoluir este projeto dentro do seu contexto

Ao reutilizar ou derivar este material:
- mantenha os avisos de licenca
- preserve os creditos de autoria quando aplicavel
- documente alteracoes relevantes feitas sobre a base original

## Autor

**Tharlesson**  
GitHub: https://github.com/tharlesson

## CI de validação local isolada

`terraform-ci / terraform` e `guardrails` usam a label exclusiva
`atlantis-run-${{ github.run_id }}`, com timeout de 20 minutos e `contents: read`.
Push em `master`/`main` e PR são preservados. Checkout usa commit completo da
action, head exato do PR ou SHA do push e `persist-credentials: false`.
A admissão por repo/workflow/job/evento/SHA cabe ao controlador revisado separado;
este patch não instala perfil nem autoriza código de fork ou qualquer SHA.

Cada job exige marker em VM Linux ARM64 e nega mounts compartilhados,
SSH agent, credenciais/perfis AWS e variáveis do gateway local de artifacts.
Metadata AWS fica desativada; arquivos AWS de configuração/credenciais são nulos.
Terraform 1.9.8 Linux ARM64 é baixado do endpoint oficial com SHA256 fixo
verificado antes da extração e instalado apenas em RUNNER_TEMP, sem sudo.

Permanecem idênticos o fmt recursivo, init da stack raiz com
`-backend=false -input=false -no-color`, `validate -no-color` e a checagem dos
três exemplos. Não há plan/apply/deploy nesta CI. Arquivos Terraform, IAM/ECS,
exemplos de Atlantis e instruções existentes de operação não foram alterados.
Os comandos de provisionamento documentados acima permanecem fora desta migração
e não foram executados.

Provas locais usam Terraform de mesma versão Darwin ARM64, verificado por SHA256,
em cópia descartável com HOME, TF_DATA_DIR e cache próprios, sem herdar ambiente,
credenciais, perfis ou SSO AWS; os arquivos AWS são /dev/null e metadata é desativada.
São provas de fonte/validação: não comprovam infraestrutura cloud nem CI real Linux.
Sem Docker/VM, API write, Root/runtime, commit/push ou alteração Code Quality.
Antes de publicar, requer revisão independente Main; rollback nesta fase é não
publicar/admitir esta fonte. Escopo: dois workflows e este README.

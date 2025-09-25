# Repository Guidelines

## Project Structure & Module Organization
- `terraform/aws`: EKS cluster, VPC, IAM, providers; primary entry for AWS.
- `terraform/aws-helm`: Helm add‑ons for EKS (ALB Controller, ExternalDNS, Autoscaler, Metrics Server).
- `terraform/bootstrap`: Bootstrap helpers (e.g., ECR/GCP bootstrap).
- `terraform/gcp` and `terraform/gcp/bootstrap`: GKE variant with Makefile‑driven workflow.
- `helm-example/new-chart`: Minimal Helm chart scaffold.
- `aws-nuke.yaml`: Cleanup tooling; use with extreme caution.

## Build, Test, and Development Commands
- Prereqs (macOS/Linux): `brew install awscli tfenv`; then `cd terraform/aws && tfenv install`.
- AWS EKS: `cd terraform/aws && terraform init ... && terraform apply -var "interviewee_name=<you>"`.
- Helm add‑ons: `cd terraform/aws-helm && terraform init && terraform apply`.
- GCP GKE: `cd terraform/gcp && make init && make plan && make apply` (see `make help`).
- Clean up: `terraform destroy ...` or `aws-nuke run --config aws-nuke.yaml` (only on disposable accounts).

## Coding Style & Naming Conventions
- Terraform: 2‑space indent; variables `snake_case`; resources/modules lower‑kebab. Run `terraform fmt -recursive` and `terraform validate` before PRs.
- Python (app): PEP8, 4‑space indent; small, single‑purpose functions; pin dependencies in `requirements.txt`.
- Files: group by provider/module; keep `variables.tf`, `outputs.tf`, `*.tf` logical and minimal.

## Testing Guidelines
- Infra: `terraform validate`, then `terraform plan` (use `-var-file` where applicable). Prefer test projects/regions. Avoid destructive tests.
- App: `make run` to sanity check locally (http://localhost:8000). If extending, add unit tests (pytest) and keep failure rate logic deterministic in tests.

## Commit & Pull Request Guidelines
- Commits: imperative, present tense; concise subject (≤72 chars); scope paths when helpful (e.g., `terraform/aws:`).
- PRs: clear description, rationale, and impact; include relevant `terraform plan` excerpts, screenshots/logs, and verification steps (e.g., `kubectl get nodes`, app URL).

## Security & Configuration Tips
- Never commit secrets or state; use S3/GCS backends. Prefer OIDC/IAM roles over static keys. Set `AWS_PROFILE`/`gcloud` ADC locally.
- Lock down CIDR vars; verify regions. Review `aws-nuke.yaml` ignorelist before use.

## Agent‑Specific Instructions
- Scope: entire repo. Keep diffs minimal; don’t rename files without reason. Run `terraform fmt` and validate. Avoid destructive commands unless explicitly requested.

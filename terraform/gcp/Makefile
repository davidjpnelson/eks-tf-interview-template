# GCP Terraform Makefile
PROJECT_ID = pp-development-466213
REGION = us-central1
CLUSTER_NAME = gke-cluster

.PHONY: help login setup init plan apply destroy clean status set-quota-project tfenv-install tfenv-use terraform-version

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

login: ## Login to GCP and set project
	@echo "Logging into GCP project: $(PROJECT_ID)"
	gcloud auth login
	gcloud auth application-default login
	gcloud config set project $(PROJECT_ID)
	gcloud auth application-default set-quota-project $(PROJECT_ID)
	@echo "Current project: $$(gcloud config get-value project)"
	@echo "Quota project set to: $(PROJECT_ID)"

setup: login ## Setup GCP project and enable required APIs
	@echo "Enabling required APIs..."
	gcloud services enable container.googleapis.com
	gcloud services enable compute.googleapis.com
	gcloud services enable iam.googleapis.com
	@echo "APIs enabled successfully"

tfenv-install: ## Install the required Terraform version using tfenv
	@echo "Installing Terraform $(shell cat .terraform-version) using tfenv..."
	tfenv install $(shell cat .terraform-version)
	@echo "Terraform $(shell cat .terraform-version) installed successfully"

tfenv-use: ## Switch to the required Terraform version using tfenv
	@echo "Switching to Terraform $(shell cat .terraform-version)..."
	tfenv use $(shell cat .terraform-version)
	@echo "Now using Terraform: $$(terraform version --json | jq -r '.terraform_version')"

terraform-version: ## Show current Terraform version
	@echo "Required version: $$(cat .terraform-version)"
	@echo "Current version: $$(terraform version --json | jq -r '.terraform_version' 2>/dev/null || echo 'Not available')"
	@echo "Available versions: $$(tfenv list 2>/dev/null || echo 'tfenv not available')"

init: tfenv-use ## Initialize Terraform (with version check)
	terraform init

plan: ## Plan Terraform deployment
	terraform plan

apply: ## Apply Terraform configuration
	terraform apply

destroy: ## Destroy all Terraform resources
	terraform destroy

clean: ## Clean Terraform cache and state
	rm -rf .terraform/
	rm -f .terraform.lock.hcl

status: ## Show current GCP and Terraform status
	@echo "=== GCP Status ==="
	@echo "Current project: $$(gcloud config get-value project)"
	@echo "Current account: $$(gcloud config get-value account)"
	@echo ""
	@echo "=== Terraform Status ==="
	@if [ -f terraform.tfstate ]; then \
		echo "Terraform state exists"; \
		terraform show -json | jq -r '.values.root_module.resources[].address' 2>/dev/null || echo "No resources in state"; \
	else \
		echo "No Terraform state found"; \
	fi

connect: ## Configure kubectl to connect to the GKE cluster
	@echo "Configuring kubectl for cluster: $(CLUSTER_NAME)"
	gcloud container clusters get-credentials $(CLUSTER_NAME) --region $(REGION) --project $(PROJECT_ID)
	kubectl cluster-info

set-quota-project: ## Set the quota project for Application Default Credentials
	@echo "Setting quota project to: $(PROJECT_ID)"
	gcloud auth application-default set-quota-project $(PROJECT_ID)
	@echo "Quota project set successfully"

vars: ## Copy example variables file
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "terraform.tfvars created from example. Please edit with your values."; \
	else \
		echo "terraform.tfvars already exists"; \
	fi

deploy: vars tfenv-install init plan apply connect ## Full deployment: setup vars, install terraform, init, plan, apply, and connect

# Development targets
dev-apply: ## Quick apply for development (auto-approve)
	terraform apply -auto-approve

dev-destroy: ## Quick destroy for development (auto-approve)
	terraform destroy -auto-approve 
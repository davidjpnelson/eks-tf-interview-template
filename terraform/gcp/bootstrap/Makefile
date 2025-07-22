# Default shell
SHELL := /bin/bash

# Variables
TF := terraform
TFVARS_FILE := bootstrap.tfvars
export GOOGLE_PROJECT := unbreakable-republic-shared

.PHONY: help init plan apply validate lint fmt clean destroy

# Show help
help:
	@echo "Available commands:"
	@echo "  make init      - Initialize Terraform"
	@echo "  make plan      - Plan Terraform changes"
	@echo "  make apply     - Apply Terraform changes"
	@echo "  make validate  - Validate Terraform configuration"
	@echo "  make lint      - Run Terraform formatting and validation"
	@echo "  make fmt       - Format Terraform files"
	@echo "  make clean     - Clean Terraform artifacts"
	@echo "  make destroy   - Destroy infrastructure (use with caution!)"

# Check if bootstrap.tfvars exists
check-tfvars:
	@if [ ! -f $(TFVARS_FILE) ]; then \
		echo "Error: $(TFVARS_FILE) not found. Please copy bootstrap.tfvars.example to bootstrap.tfvars and update the values."; \
		exit 1; \
	fi

# Initialize Terraform
init:
	$(TF) init

# Validate Terraform configuration
validate: init
	$(TF) validate

# Format Terraform files
fmt:
	$(TF) fmt -recursive

# Lint (format + validate)
lint: fmt validate
	@echo "Terraform linting completed successfully"

# Plan Terraform changes
plan: check-tfvars validate
	$(TF) plan -var-file=$(TFVARS_FILE)

# Apply Terraform changes
apply: check-tfvars validate
	$(TF) apply -var-file=$(TFVARS_FILE)

# Apply with auto-approve (use with caution)
apply-auto: check-tfvars validate
	$(TF) apply -var-file=$(TFVARS_FILE) -auto-approve

# Destroy infrastructure (use with extreme caution!)
destroy: check-tfvars
	@echo "WARNING: This will destroy all infrastructure managed by this Terraform configuration!"
	@echo "This action cannot be undone!"
	@read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(TF) destroy -var-file=$(TFVARS_FILE); \
	else \
		echo "Destroy cancelled."; \
	fi

# Show Terraform state
show:
	$(TF) show

# List Terraform resources
list:
	$(TF) state list

# Clean Terraform artifacts
clean:
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfplan

# Output values
output:
	$(TF) output

# Refresh state
refresh: check-tfvars
	$(TF) refresh -var-file=$(TFVARS_FILE)

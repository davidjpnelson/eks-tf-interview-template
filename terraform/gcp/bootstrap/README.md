# Bootstrap Infrastructure

This directory contains the bootstrap infrastructure for the Unbreakable Republic organization. This creates the foundational resources needed before other Terraform configurations can be applied.

## Purpose

The bootstrap infrastructure creates:
- Google Cloud Storage bucket for Terraform state
- IAM permissions for Terraform service accounts
- Initial project setup and configuration

## Prerequisites

1. Install required tools:
   ```bash
   brew install tfenv
   brew install google-cloud-sdk
   ```

2. Install Terraform version:
   ```bash
   tfenv install
   tfenv use
   ```

3. Authenticate with Google Cloud:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

4. Set your project:
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

## Initial Setup

1. Navigate to the bootstrap directory:
   ```bash
   cd iac/bootstrap
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your specific values:
   - Update project ID
   - Update organization details
   - Update bucket name (must be globally unique)

4. Initialize Terraform:
   ```bash
   terraform init
   ```

5. Plan and apply:
   ```bash
   terraform plan
   terraform apply
   ```

## After Bootstrap

Once the bootstrap is complete:

1. The Terraform state bucket will be created
2. Update other Terraform configurations to use the remote state
3. Configure backend in `versions.tf` of other modules

## Important Notes

- **Run this only once** per organization/project
- **State is stored locally** for bootstrap (chicken-and-egg problem)
- **Backup the local state file** after successful apply
- **Don't delete** the bootstrap resources without migrating state first

## Repository Structure

This should be run in the `unbreakable-republic-shared` repository:

```
unbreakable-republic-shared/
├── iac/
│   └── bootstrap/          # This directory
│       ├── README.md       # This file
│       ├── .terraform-version
│       ├── versions.tf
│       ├── variables.tf
│       ├── main.tf
│       ├── outputs.tf
│       └── terraform.tfvars.example
└── ...
``` 
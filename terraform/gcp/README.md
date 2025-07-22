# GCP Terraform Configuration

This directory contains Terraform configuration for setting up a Google Kubernetes Engine (GKE) cluster on Google Cloud Platform.

**Project ID**: `pp-development-466213`

## Quick Start with Makefile

The easiest way to get started is using the provided Makefile:

```bash
# Login to GCP and setup the project
make login

# Setup APIs and deploy everything
make deploy

# Or step by step:
make setup           # Enable required APIs
make tfenv-install   # Install correct Terraform version
make init           # Initialize Terraform
make plan           # Plan the deployment
make apply          # Apply the configuration
make connect        # Configure kubectl
```

## Prerequisites

1. **Google Cloud CLI**: Install and configure the gcloud CLI
   ```bash
   # Install gcloud CLI (if not already installed)
   # See: https://cloud.google.com/sdk/docs/install
   ```

2. **tfenv**: Install tfenv for Terraform version management
   ```bash
   # On macOS with Homebrew
   brew install tfenv
   
   # On Linux
   git clone https://github.com/tfutils/tfenv.git ~/.tfenv
   echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
   ```

3. **Make**: Ensure you have `make` installed for using the Makefile targets

## Understanding Quota Projects

A **quota project** in GCP is the project that:
- Gets billed for API calls made by your applications
- Enforces API quotas and rate limits
- Must have the required APIs enabled
- Must have billing enabled

The `make login` command automatically sets `pp-development-466213` as your quota project to avoid quota-related errors.

## Manual Setup (Alternative to Makefile)

If you prefer manual setup:

1. **Authenticate with Google Cloud**:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project pp-development-466213
   gcloud auth application-default set-quota-project pp-development-466213
   ```

2. **Enable required APIs**:
   ```bash
   gcloud services enable container.googleapis.com
   gcloud services enable compute.googleapis.com
   gcloud services enable iam.googleapis.com
   ```

3. **Copy and configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your preferences (project_id is already set)
   ```

4. **Install latest Terraform version and initialize**:
   ```bash
   tfenv install latest
   tfenv use latest
   terraform init
   terraform plan
   terraform apply
   ```

## What This Creates

- **GKE Cluster**: A regional GKE cluster with autoscaling enabled
- **VPC Network**: Custom VPC with proper subnetting for pods and services  
- **Node Pool**: Managed node pool with preemptible instances
- **Service Account**: Custom service account with necessary IAM roles
- **Firewall Rules**: Basic firewall rules for cluster communication

## Connecting to the Cluster

After successful deployment, configure kubectl:

```bash
# Using the Makefile (recommended)
make connect

# Or manually
gcloud container clusters get-credentials gke-cluster --region us-central1 --project pp-development-466213

# Or use the Terraform output command
terraform output kubectl_config_command
```

## Key Features

- **Workload Identity**: Enabled for secure pod-to-GCP-service communication
- **Network Policy**: Enabled for network security
- **Autoscaling**: Node pool can scale from 1 to 10 nodes
- **Auto-repair/Auto-upgrade**: Automatic node maintenance
- **Preemptible Nodes**: Cost-effective compute instances

## Outputs

The configuration provides several useful outputs:
- Cluster name and endpoint
- Service account information
- Network details
- kubectl configuration command

## Available Makefile Targets

Run `make help` to see all available targets:

- `make login` - Login to GCP and set project (includes quota project setup)
- `make setup` - Enable required APIs  
- `make tfenv-install` - Install the latest Terraform version
- `make tfenv-use` - Switch to the required Terraform version
- `make terraform-version` - Show current and required Terraform versions
- `make init` - Initialize Terraform (automatically uses correct version)
- `make plan` - Plan Terraform deployment
- `make apply` - Apply Terraform configuration
- `make connect` - Configure kubectl for the cluster
- `make deploy` - Full deployment (vars + tfenv + init + plan + apply + connect)
- `make status` - Show current GCP and Terraform status
- `make set-quota-project` - Set quota project for Application Default Credentials
- `make destroy` - Destroy all resources
- `make clean` - Clean Terraform cache

## Cleanup

To destroy all resources:
```bash
make destroy
# Or manually:
terraform destroy
```

## Notes

- The configuration uses preemptible instances for cost savings
- Network policy is enabled for enhanced security
- The setup follows GCP best practices for production workloads
- Backend state is stored in S3 (can be changed to GCS if preferred) 
# GCP Project Configuration
project_id = "gcp-interviews-meyerkev"
region     = "us-central1"

# Environment
environment = "shared"

# Terraform State Bucket
# Note: This must be globally unique across all of GCS
terraform_state_bucket_name = "gcp-interviews-meyerkev-terraform-state"

# Labels
labels = {
  managed-by  = "terraform"
  purpose     = "bootstrap"
  environment = "shared "
} 
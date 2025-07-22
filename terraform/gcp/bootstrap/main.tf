# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Get current project info
data "google_project" "current" {}

# Enable required APIs
resource "google_project_service" "storage_api" {
  service = "storage.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "iam_api" {
  service = "iam.googleapis.com"

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Create the Terraform state bucket
resource "google_storage_bucket" "terraform_state" {
  name          = var.terraform_state_bucket_name
  location      = var.region
  force_destroy = false

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }

  # Enable versioning for state file history
  versioning {
    enabled = true
  }

  # Use Google-managed encryption (no custom KMS key)
  # Omitting encryption block uses Google-managed encryption by default

  # Access controls
  uniform_bucket_level_access = true

  # Keep only the latest 10 versions
  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(var.labels, {
    environment = var.environment
    bucket-type = "terraform-state"
  })

  depends_on = [google_project_service.storage_api]
}

# IAM binding for the bucket - allow current user and service account to manage state
resource "google_storage_bucket_iam_binding" "terraform_state_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.terraform.email}",
  ]
}

# Create a service account for Terraform operations (optional)
resource "google_service_account" "terraform" {
  account_id   = "terraform-automation"
  display_name = "Terraform Service Account"
  description  = "Service account used by Terraform for infrastructure management"
}

# Grant the service account necessary permissions
resource "google_project_iam_member" "terraform_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_storage_bucket_iam_member" "terraform_state_access" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.terraform.email}"
}

# Note: Service account key creation is disabled by organizational policy
# Instead, use one of these authentication methods:
# 1. gcloud auth application-default login (for local development)
# 2. Workload Identity (for CI/CD)
# 3. Instance service accounts (for compute instances) 
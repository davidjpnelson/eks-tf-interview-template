output "terraform_state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "terraform_state_bucket_url" {
  description = "URL of the Terraform state bucket"
  value       = google_storage_bucket.terraform_state.url
}

output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "terraform_service_account_email" {
  description = "Email of the Terraform service account"
  value       = google_service_account.terraform.email
}

output "authentication_note" {
  description = "Authentication instructions for using the service account"
  value = <<-EOT
Use one of these authentication methods:

1. For local development:
   gcloud auth application-default login

2. For CI/CD (GitHub Actions, etc.):
   Use Workload Identity Federation

3. For compute instances:
   Use instance service accounts

Service account email: ${google_service_account.terraform.email}
EOT
}

output "backend_config" {
  description = "Backend configuration for other Terraform configurations"
  value = {
    bucket = google_storage_bucket.terraform_state.name
    prefix = "terraform/state"
  }
}

output "backend_config_example" {
  description = "Example backend configuration to use in other Terraform configurations"
  value = <<-EOT
terraform {
  backend "gcs" {
    bucket = "${google_storage_bucket.terraform_state.name}"
    prefix = "terraform/state"
  }
}
EOT
} 
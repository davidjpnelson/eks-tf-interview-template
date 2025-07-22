variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "gcp-interviews-meyerkev"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "terraform_state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state (must be globally unique)"
  type        = string
  default     = "gcp-interviews-meyerkev-terraform-state"
}

variable "environment" {
  description = "Environment (e.g., shared, prod, dev)"
  type        = string
  default     = "shared"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    managed-by = "terraform"
    purpose    = "bootstrap"
  }
} 
variable "region" {
  description = "The region to deploy to"
  type        = string
  default     = "us-east-2"
}

variable "interview_name" {
  description = "Identifier for this interview; used for ECR repo name and tags (e.g., 'interview-repo', 'acme-takehome')."
  type        = string
  default     = "interview-repo"
}

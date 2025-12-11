variable "project_id" {
  description = "The ID of the GCP project"
  type        = string
}

variable "region" {
  description = "The GCP region for the Functions and Scheduler"
  type        = string
  default     = "us-central1"
}

variable "firestore_region" {
  description = "The region for the Firestore database"
  type        = string
  default     = "nam5" # Multi-region for the free tier
}
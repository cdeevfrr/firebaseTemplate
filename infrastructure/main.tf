# Sets up the terraform providers, and the firebase project & webapp.

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    # Used for managing Firebase-specific resources
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

# Configure the provider with project and region from variables.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ---
# 2. FIREBASE
# ---

# Enables the Firebase API (for Hosting and Auth)
resource "google_project_service" "firebase_api" {
  project = var.project_id
  service = "firebase.googleapis.com"
  disable_on_destroy = false
}

# Creates a Firebase Web App instance
resource "google_firebase_web_app" "web_app" {
  provider     = google-beta 
  # This creates a web app to host the React code and get client config
  project      = var.project_id
  display_name = "My Graph App Web App"
  depends_on   = [google_project_service.firebase_api]
}
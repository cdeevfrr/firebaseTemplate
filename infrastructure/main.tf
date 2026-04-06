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
# FIREBASE
# ---

# Explicitly provision the Firebase project layer on the existing GCP project.
# This step is crucial for Firebase-specific resources (like google_firebase_web_app)
# to recognize the project.
resource "google_firebase_project" "default" {
  provider = google-beta
  project = var.project_id # Uses your existing GCP Project ID
  # No other settings are strictly required for this resource.
  # Doesn't delete - once a GCP project has firebase enabled, it cannot be disabled. 
}

# Enables the Firebase API (for Hosting and Auth)
resource "google_project_service" "firebase_api" {
  project = var.project_id
  service = "firebase.googleapis.com"
}

# Creates a Firebase Web App instance
resource "google_firebase_web_app" "web_app" {
  provider     = google-beta 
  # This creates a web app to host the React code and get client config
  display_name = "REPLACE ME"
  depends_on   = [
    google_project_service.firebase_api, 
    google_firebase_project.default
  ]
}
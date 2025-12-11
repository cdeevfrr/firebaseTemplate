# 1. PROVIDERS & BACKEND
# ---
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

# ---
# 2. FIREBASE / FIRESTORE RESOURCES
# ---

# Enables the Firebase API (for Hosting and Auth)
resource "google_project_service" "firebase_api" {
  project = var.project_id
  service = "firebase.googleapis.com"
  disable_on_destroy = false
}

# Creates a Firebase Web App instance
resource "google_firebase_web_app" "web_app" {
  # This creates a web app to host the React code and get client config
  project      = var.project_id
  display_name = "My Graph App Web App"
  depends_on = [google_project_service.firebase_api]
}

# Creates the Firestore Database (Native Mode)
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "default-database"
  location_id = var.firestore_region
  type        = "FIRESTORE_NATIVE" # Only other option is an out dated type.
}

# Deploy the Firestore Security Rules
# NOTE: The actual content of firestore.rules is defined in the functions folder
resource "google_firebaserules_ruleset" "firestore" {
  project = var.project_id
  source {
    files {
      name    = "firestore.rules"
      content = file("${path.root}/../functions/firestore.rules") # Read file content
    }
  }
  lifecycle {
    # Allows a new ruleset to be created and released before the old one is destroyed.
    create_before_destroy = true
  }
}

# Release the ruleset to the 'cloud.firestore' release name
resource "google_firebaserules_release" "firestore_release" {
  project      = var.project_id
  name         = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore.name
  depends_on   = [google_firestore_database.database]
}

# ---
# 3. CLOUD FUNCTIONS AND SCHEDULER
# ---

# Service Account for the scheduled job to run under
resource "google_service_account" "scheduler_sa" {
  account_id   = "scheduler-sa"
  display_name = "Cloud Scheduler Invoker SA"
}

# 3a. Scheduled Compute Function (Runs every minute, private)
# NOTE: The function's code is uploaded via the Firebase CLI deployment step, 
# not directly in this Terraform. We only create the container for the function.

resource "google_cloudfunctions2_function" "scheduled_func" {
  project  = var.project_id
  name     = "scheduled-job-processor"
  location = var.region
  build_config {
    runtime     = "nodejs20"
    entry_point = "scheduledJob"
  }
  service_config {
    max_instance_count = 1 # Keep it low for free tier
    ingress_settings   = "ALLOW_INTERNAL_ONLY" # Crucial: Only accessible by GCP services
    service_account_email = google_service_account.scheduler_sa.email # Use the dedicated SA
    available_memory   = "128Mi"
  }
}

# TODO: make another function that computes optimal portfolio given the saved graph.

# IAM binding to allow the scheduled job's Service Account to invoke the function
resource "google_cloudfunctions2_function_iam_member" "scheduled_invoker" {
  project        = var.project_id
  location       = google_cloudfunctions2_function.scheduled_func.location
  cloud_function = google_cloudfunctions2_function.scheduled_func.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.scheduler_sa.email}"
}

# Create the Cloud Scheduler Job
resource "google_cloud_scheduler_job" "minute_job" {
  project     = var.project_id
  name        = "minute-graph-check"
  region      = var.region
  schedule    = "* * * * *" # Every minute
  time_zone   = "America/New_York"
  description = "Checks graph state and performs updates."

  http_target {
    uri         = google_cloudfunctions2_function.scheduled_func.service_config.uri
    http_method = "POST"
    # Authentication for the private function
    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = google_cloudfunctions2_function.scheduled_func.service_config.uri
    }
  }
}

# Enables the Cloud Functions API (Required to run functions)
resource "google_project_service" "cloudfunctions_api" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
}

# Enables the Cloud Run API (which Cloud Functions 2nd Gen relies on)
resource "google_project_service" "cloudrun_api" {
  project = var.project_id
  service = "run.googleapis.com"
}

# Enables the Cloud Build API (required for Cloud Functions/Cloud Run to create your function)
resource "google_project_service" "cloudbuild_api" {
  project            = var.project_id
  service            = "cloudbuild.googleapis.com"
}

# Service Account for the function to run under
resource "google_service_account" "backend_sa" {
  account_id   = "backend-sa"
  display_name = "Backend SA"
}

# Bucket for the source code
# Make a new random bucket,
# upload the zipped function folder as 
# an object in that bucket.

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.default.hex}-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "../functions/backendFunction/"
}

resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
}

# Backend function responds to most client-side requests
resource "google_cloudfunctions2_function" "backend_func" {
  project  = var.project_id
  name     = "backend"
  location = var.region
  build_config {
    runtime     = "nodejs22"
    entry_point = "handleUserRequest"
    source {
      storage_source {
        bucket = google_storage_bucket.default.name
        object = google_storage_bucket_object.object.name
      }
    }
  }
  service_config {
    max_instance_count = 1 # Keep it low for free tier
    ingress_settings   = "ALLOW_INTERNAL_ONLY" # Crucial: Only accessible by GCP services
    service_account_email = google_service_account.backend_sa.email # Use the dedicated SA
    available_memory   = "128Mi"
  }
 
  depends_on = [
    google_project_service.cloudfunctions_api,
    google_project_service.cloudbuild_api,
    google_project_service.cloudrun_api,
  ]
}

# Grant general Firestore/Datastore access to the Service Account.
# Using roles/datastore.user provides read/write access to data in firestore 
# (firestore uses datastore)
resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}
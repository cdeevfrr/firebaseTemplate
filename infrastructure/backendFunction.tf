
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



data "archive_file" "backend_func_zip" {
  type        = "zip"
  output_path = "${path.module}/.tmp/backend-func.zip"
  source_dir  = "../functions/backendFunction/"

  excludes = [
    "node_modules",
    "dist",
    ".env"
  ]
}

resource "google_storage_bucket_object" "backend_source_object" {
  name   = "source-${data.archive_file.backend_func_zip.output_md5}.zip" # MD5 forces redeploy on code change
  bucket = google_storage_bucket.default.name
  source = data.archive_file.backend_func_zip.output_path
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
        object = google_storage_bucket_object.backend_source_object.name
      }
    }
  }
  service_config {
    max_instance_count = 1 # Keep it low for free tier
    ingress_settings = "ALLOW_ALL" # This allows the function to be reached from the internet
    service_account_email = google_service_account.backend_sa.email # Use the dedicated SA
    available_memory   = "256Mi"
  }
 
  depends_on = [
    google_project_service.cloudfunctions_api,
    google_project_service.cloudbuild_api,
    google_project_service.cloudrun_api,
  ]
}

# Allow public access to the function
# Since we are handling auth INSIDE the code via Firebase Admin SDK, 
# you need to make the function "public" so the client side requests can reach it.
resource "google_cloud_run_service_iam_member" "public_invoker" {
  location = google_cloudfunctions2_function.backend_func.location
  project  = google_cloudfunctions2_function.backend_func.project
  service  = google_cloudfunctions2_function.backend_func.name
  role     = "roles/run.invoker"
  member   = "allUsers" # Use "allUsers" for public, or restrict if using App Check
}

# Grant general Firestore/Datastore access to the Service Account.
# Using roles/datastore.user provides read/write access to data in firestore 
# (firestore uses datastore)
resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}
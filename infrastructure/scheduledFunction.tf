
# Enables the Cloud Functions API
resource "google_project_service" "cloudfunctions_api" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}

# Enables the Cloud Run API (which Cloud Functions 2nd Gen relies on)
resource "google_project_service" "cloudrun_api" {
  project = var.project_id
  service = "run.googleapis.com"
  disable_on_destroy = false
}

# Enables the Cloud Scheduler API
resource "google_project_service" "cloudscheduler_api" {
  project = var.project_id
  service = "cloudscheduler.googleapis.com"
  disable_on_destroy = false
}


# 1 Service Account for the scheduled job to run under
resource "google_service_account" "scheduler_sa" {
  account_id   = "scheduler-sa"
  display_name = "Cloud Scheduler Invoker SA"
}

# 2 Bucket for the source code
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
  source_dir  = "../functions/scheduledFunction/"
}

resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
}

# 3 Scheduled Compute function

resource "google_cloudfunctions2_function" "scheduled_func" {
  project  = var.project_id
  name     = "scheduled-job-processor"
  location = var.region
  build_config {
    runtime     = "nodejs22"
    entry_point = "myTypescriptFunction"
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
    service_account_email = google_service_account.scheduler_sa.email # Use the dedicated SA
    available_memory   = "128Mi"
  }
 
  depends_on = [
    google_project_service.cloudfunctions_api,
    google_project_service.cloudrun_api,
    google_project_service.cloudscheduler_api
  ]
}


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
  paused      = true
  project     = var.project_id
  name        = "minute-graph-check"
  region      = var.region
  schedule    = "*/30 * * * *" # Every 30 minutes
  time_zone   = "America/New_York"
  description = "Checks graph state and performs updates."

  http_target {
    uri         = google_cloudfunctions2_function.scheduled_func.service_config[0].uri
    http_method = "POST"
    # Authentication for the private function
    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = google_cloudfunctions2_function.scheduled_func.service_config[0].uri
    }
  }
}

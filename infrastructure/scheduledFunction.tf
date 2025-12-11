
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
    uri         = google_cloudfunctions2_function.scheduled_func.service_config[0].uri
    http_method = "POST"
    # Authentication for the private function
    oidc_token {
      service_account_email = google_service_account.scheduler_sa.email
      audience              = google_cloudfunctions2_function.scheduled_func.service_config[0].uri
    }
  }
}

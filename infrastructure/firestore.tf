# Enables the Cloud Firestore API
resource "google_project_service" "firestore_api" {
  project            = var.project_id
  service            = "firestore.googleapis.com"
}

# Creates the Firestore Database (Native Mode)
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "default-database"
  location_id = var.firestore_region
  type        = "FIRESTORE_NATIVE" # Only other option is an out dated type.
  # Somewhat risky deletion deletion_policy:
  # If you're doing a real app, recommended to change this to ABANDON.
  deletion_policy = "DELETE"

  depends_on = [
    google_project_service.firebase_api, 
    google_project_service.firestore_api
  ]
}

# Deploy the Firestore Security Rules
resource "google_firebaserules_ruleset" "firestore" {
  project = var.project_id
  source {
    files {
      name    = "firestore.rules"
      content = file("${path.root}/firestore_rules.txt") # Read file content
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
  name         = "cloud.firestore/${google_firestore_database.database.name}"
  ruleset_name = google_firebaserules_ruleset.firestore.name
  depends_on   = [google_firestore_database.database]
}
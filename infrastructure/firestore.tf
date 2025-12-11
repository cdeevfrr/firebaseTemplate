# Creates the Firestore Database (Native Mode)
resource "google_firestore_database" "database" {
  project     = var.project_id
  name        = "default-database"
  location_id = var.firestore_region
  type        = "FIRESTORE_NATIVE" # Only other option is an out dated type.
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
  name         = "cloud.firestore"
  ruleset_name = google_firebaserules_ruleset.firestore.name
  depends_on   = [google_firestore_database.database]
}
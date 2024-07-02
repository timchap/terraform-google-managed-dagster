

resource "google_storage_bucket" "logs" {
  name     = var.log_bucket
  location = var.region
  project  = var.project

  lifecycle_rule {
    condition {
      age = var.log_bucket_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "io" {
  name     = var.io_bucket
  location = var.region
  project  = var.project
}
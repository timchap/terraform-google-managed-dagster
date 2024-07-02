

resource "google_storage_bucket" "logs" {
  name     = "cfarm-tech-${local.env}-dagsterlogs"
  location = "europe-west1"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "io" {
  name     = "cfarm-tech-${local.env}-dagsterio"
  location = "europe-west1"

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
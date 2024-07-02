
resource "google_service_account" "primary" {
  account_id   = var.primary_service_account_name
  project      = var.project
  display_name = "Service Account for Dagster webserver, daemon and code servers"
}

resource "google_service_account" "run_worker" {
  for_each     = var.code_locations
  account_id   = "${var.run_worker_service_account_prefix}${each.key}"
  project      = var.project
  display_name = "Dagster run worker for code location ${each.key}"
}
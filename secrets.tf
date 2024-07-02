resource "google_secret_manager_secret" "dagster_db_password" {
  secret_id = "${var.db_instance_name}-${var.db_user}-password"
  project   = var.project
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "dagster_db_password" {
  secret      = google_secret_manager_secret.dagster_db_password.id
  secret_data = random_password.password.result
}
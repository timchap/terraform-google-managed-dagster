

# Code servers allow unauthenticated requests as they are only accessible from the internal network.
resource "google_cloud_run_v2_service_iam_member" "code_server_is_open" {
  for_each = google_cloud_run_v2_service.code_server
  name     = each.value.name
  location = each.value.location
  role     = "roles/run.invoker"
  member   = "allUsers"
  project = var.project
}

resource "google_cloud_run_v2_job_iam_member" "primary_can_execute_run_worker" {
  for_each = google_cloud_run_v2_job.run_worker
  name     = each.value.name
  location = each.value.location
  role     = "roles/run.admin"
  member   = google_service_account.primary.member
  project = var.project
}

# For some reason, setting run.developer or even run.admin permissions at job level
# does not allow executions to be cancelled. So we need to set it at project level.
resource "google_project_iam_member" "primary_can_execute_run_worker" {
  role    = "roles/run.developer"
  member  = google_service_account.primary.member
  project = var.project
}

resource "google_secret_manager_secret_iam_member" "primary_can_get_secrets" {
  secret_id = google_secret_manager_secret.dagster_db_password.secret_id
  project = var.project
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.primary.member
}

resource "google_secret_manager_secret_iam_member" "run_workers_can_get_secrets" {
  for_each  = google_service_account.run_worker
  secret_id = google_secret_manager_secret.dagster_db_password.secret_id
  project = var.project
  role      = "roles/secretmanager.secretAccessor"
  member    = each.value.member
}
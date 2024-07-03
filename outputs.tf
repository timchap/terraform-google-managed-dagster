
output "code_servers" {
  value = google_cloud_run_v2_service.code_server
  description = "The Cloud Run services for code servers"
}

output "webserver" {
  value = google_cloud_run_v2_service.webserver
  description = "The Cloud Run service for the webserver"
}

output "run_workers" {
  value = google_cloud_run_v2_job.run_worker
  description = "The Cloud Run jobs for run workers"
}

output "daemon" {
  value = google_compute_instance.daemon
  description = "The Compute Engine instance for the daemon"
}

output "primary_service_account" {
  value = google_service_account.primary
  description = "The primary service account"
}

output "run_worker_service_accounts" {
  value = google_service_account.run_worker
  description = "The service accounts for run workers"
}
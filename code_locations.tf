


resource "google_cloud_run_v2_service" "code_server" {
  for_each = var.code_locations
  name     = "dagster-code-server-${each.key}"
  project  = var.project
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  labels = var.labels

  template {
    service_account = google_service_account.primary.email

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    execution_environment = var.execution_environment

    scaling {
      min_instance_count = 0
      max_instance_count = 1 # Dagster currently supports only one code server instance per code location
    }

    containers {
      image = each.value.image
      command = var.code_server_command
      args  = ["--host", "0.0.0.0", "--port", "${each.value.port}", "--module-name", each.value.module_name]

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project
      }

      env {
        name  = "DATABASE_HOST"
        value = var.db_instance_private_ip
      }

      env {
        name  = "DATABASE_USER"
        value = var.db_user
      }

      env {
        name  = "DATABASE_DBNAME"
        value = var.db_database_name
      }

      env {
        name  = "DATABASE_SCHEMA"
        value = var.db_schema
      }

      env {
        name = "DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.dagster_db_password.secret_id
            version = google_secret_manager_secret_version.dagster_db_password.version
          }
        }
      }

      ports {
        name           = "h2c"
        container_port = each.value.port
      }

      resources {
        limits = {
          memory = var.code_server_resources.limits.memory
          cpu    = var.code_server_resources.limits.cpu
        }
        cpu_idle = var.code_server_resources.cpu_idle
      }

      startup_probe {
        grpc {
          port    = 3000
          service = "DagsterApi"
        }
        initial_delay_seconds = 0
        timeout_seconds       = 30
        period_seconds        = 30
        failure_threshold     = 2
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.primary_can_get_secrets
  ]
}

resource "google_cloud_run_v2_job" "run_worker" {
  for_each = google_service_account.run_worker
  name     = "dagster-run-worker-${each.key}"
  project  = var.project
  location = var.region

  labels = var.labels

  template {
    template {
      service_account = each.value.email

      max_retries = 0

      vpc_access {
        connector = var.vpc_connector_id
        egress    = "PRIVATE_RANGES_ONLY"
      }

      timeout = "${var.run_worker_job_timeout_seconds}s"

      containers {
        image = var.code_locations[each.key].image

        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project
        }

        env {
          name  = "DATABASE_HOST"
          value = var.db_instance_private_ip
        }

        env {
          name  = "DATABASE_USER"
          value = var.db_user
        }

        env {
          name  = "DATABASE_DBNAME"
          value = var.db_database_name
        }

        env {
          name  = "DATABASE_SCHEMA"
          value = var.db_schema
        }

        env {
          name = "DATABASE_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.dagster_db_password.secret_id
              version = google_secret_manager_secret_version.dagster_db_password.version
            }
          }
        }

        resources {
          limits = var.code_locations[each.key].run_worker_resources_limits
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.run_workers_can_get_secrets
  ]

}


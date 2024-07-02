



resource "google_cloud_run_v2_service" "webserver" {
  name     = var.webserver_service_name
  location = var.region
  project  = var.project
  ingress  = var.webserver_ingress

  labels = var.labels

  template {

    labels = var.labels

    service_account = google_service_account.primary.email

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = var.webserver_min_instance_count
      max_instance_count = var.webserver_max_instance_count
    }

    execution_environment = var.execution_environment

    max_instance_request_concurrency = var.webserver_max_instance_request_concurrency

    containers {

      image = var.webserver_image
      command = var.webserver_command
      args  = var.webserver_args

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

      dynamic "env" {
        for_each = google_cloud_run_v2_service.code_server
        content {
          name  = "CODE_SERVER_HOST_${upper(env.key)}"
          value = replace(env.value.uri, "https://", "")
        }
      }

      dynamic "env" {
        for_each = var.webserver_env
        content {
          name  = env.value["name"]
          value = env.value["value"]
        }
      }

      dynamic "env" {
        for_each = var.webserver_env_secrets
        content {
          name = env.value["name"]
          value_source {
            secret_key_ref {
              secret  = env.value["secret_id"]
              version = "latest"
            }
          }
        }
      }

      ports {
        name           = "http1"
        container_port = var.webserver_port
      }

      resources {
        limits            = var.webserver_resources["limits"]
        startup_cpu_boost = var.webserver_resources["startup_cpu_boost"]
        cpu_idle          = var.webserver_resources["cpu_idle"]
      }

      startup_probe {
        initial_delay_seconds = var.webserver_startup_probe["initial_delay_seconds"]
        timeout_seconds       = var.webserver_startup_probe["timeout_seconds"]
        period_seconds        = var.webserver_startup_probe["period_seconds"]
        failure_threshold     = var.webserver_startup_probe["failure_threshold"]

        http_get {
          path = var.webserver_startup_probe["http_path"]
          port = var.webserver_startup_probe["http_port"]
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.primary_can_get_secrets
  ]

}


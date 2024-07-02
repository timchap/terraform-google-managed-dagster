
# Defines a job which is


resource "google_cloud_run_v2_job" "app" {
  name     = "${var.app_name}-migrate"
  location = var.region

  labels = {
    application = var.app_name
  }

  lifecycle {
    ignore_changes = [
      template[0].labels,
      template[0].template[0].containers[0].image,
      client,
      client_version,
      labels,
    ]
  }

  template {
    labels = {}
    template {
      max_retries     = 0
      service_account = google_service_account.app.email

      vpc_access {
        connector = var.vpc_connector_id
        egress    = "PRIVATE_RANGES_ONLY"
      }

      containers {
        image = local.image
        args  = var.container_args_migrate

        dynamic "env" {
          for_each = google_sql_database.app
          content {
            name  = lookup(var.rename_db_args, "DATABASE_HOST", "DATABASE_HOST")
            value = var.db_instance_private_ip
          }
        }

        dynamic "env" {
          for_each = google_sql_database.app
          content {
            name  = lookup(var.rename_db_args, "DATABASE_USER", "DATABASE_USER")
            value = google_sql_user.app["default"].name
          }
        }

        dynamic "env" {
          for_each = google_sql_database.app
          content {
            name  = lookup(var.rename_db_args, "DATABASE_DBNAME", "DATABASE_DBNAME")
            value = google_sql_database.app["default"].name
          }
        }

        dynamic "env" {
          for_each = google_sql_database.app
          content {
            name  = lookup(var.rename_db_args, "DATABASE_SCHEMA", "DATABASE_SCHEMA")
            value = "public"
          }
        }

        dynamic "env" {
          for_each = google_sql_database.app
          content {
            name  = lookup(var.rename_db_args, "DATABASE_PORT", "DATABASE_PORT")
            value = "5432"
          }
        }

        dynamic "env" {
          for_each = google_sql_database.app
          content {
            name = lookup(var.rename_db_args, "DATABASE_PASSWORD", "DATABASE_PASSWORD")
            value_source {
              secret_key_ref {
                secret  = google_secret_manager_secret.sql_password["default"].secret_id
                version = "latest"
              }
            }
          }
        }

        dynamic "env" {
          for_each = var.container_env
          content {
            name  = env.value["name"]
            value = env.value["value"]
          }
        }

        dynamic "env" {
          for_each = var.container_env_secrets
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
          container_port = var.container_port
        }

        resources {
          limits = {
            memory = var.memory_limit
            cpu    = var.cpu_limit
          }
        }
      }
    }
  }
  depends_on = [
    google_secret_manager_secret_iam_member.can_get_pg_password
  ]

}

locals {
  image                = var.container_image == null ? "${var.registry_location}-docker.pkg.dev/cfarm-tech-registry/web-apps/${var.app_name}:${var.default_tag}" : var.container_image
  service_account_name = var.service_account_name == null ? "${var.app_name}-app" : var.service_account_name
}

resource "google_service_account" "app" {
  account_id   = local.service_account_name
  display_name = "Service Account for ${var.app_name}"
}

resource "google_cloud_run_v2_service" "app" {
  name     = var.app_name
  location = var.region
  ingress  = var.restrict_ingress_to_internal_traffic ? "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" : "INGRESS_TRAFFIC_ALL"

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      template[0].labels,
      client,
      client_version,
    ]
  }

  labels = {
    "application" = var.app_name
  }

  template {

    labels = {
      "application" = var.app_name
    }

    service_account = google_service_account.app.email

    vpc_access {
      connector = var.vpc_connector_id
      egress    = var.vpc_access_egress
    }

    scaling {
      min_instance_count = var.min_instance_count
      max_instance_count = var.max_instance_count
    }

    execution_environment = var.execution_environment

    max_instance_request_concurrency = var.max_instance_request_concurrency

    containers {

      image = local.image
      args  = var.container_args

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
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      startup_probe {
        initial_delay_seconds = var.startup_probe["initial_delay_seconds"]
        timeout_seconds       = var.startup_probe["timeout_seconds"]
        period_seconds        = var.startup_probe["period_seconds"]
        failure_threshold     = var.startup_probe["failure_threshold"]

        http_get {
          path = var.health_check_path
          port = var.container_port
        }
      }
    }
  }

  depends_on = [
    google_secret_manager_secret_iam_member.can_get_pg_password
  ]

}
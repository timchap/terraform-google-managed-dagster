

locals {
  code_locations = {
    core = {
      image             = "europe-docker.pkg.dev/cfarm-tech-registry/dagster-cl-core/dagster-cl-core:${local.image_tag}"
      run_worker_cpu    = "1"
      run_worker_memory = "4Gi"
    }
  }
}

resource "google_cloud_run_v2_service" "code_server" {
  for_each = local.code_locations
  name     = "dagster-code-server-${each.key}"

  location = local.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  lifecycle {
    ignore_changes = [
      template[0].labels,
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  labels = {
    "application" = "dagster"
  }

  template {
    service_account = "dagster@cfarm-tech-${local.env}-apps.iam.gserviceaccount.com"

    vpc_access {
      connector = data.terraform_remote_state.bootstrap_shared.outputs.vpc_access_connectors[local.region]
      egress    = "PRIVATE_RANGES_ONLY"
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }

    containers {
      image = each.value.image
      args  = ["dagster", "api", "grpc", "--host", "0.0.0.0", "--port", "3000", "--module-name", "definitions"]

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = local.project
      }

      env {
        name  = "DATABASE_HOST"
        value = data.terraform_remote_state.postgres_shared.outputs.db_instance_private_ip
      }

      env {
        name  = "DATABASE_USER"
        value = "dagster"
      }

      env {
        name  = "DATABASE_DBNAME"
        value = "dagster"
      }

      env {
        name  = "DATABASE_SCHEMA"
        value = "public"
      }

      env {
        name = "DATABASE_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = module.webserver.sql_password_secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "DAGSTER_EVENT_BATCH_SIZE"
        value = "25"
      }

      ports {
        name           = "h2c"
        container_port = 3000
      }

      resources {
        limits = {
          memory = "2Gi"
          cpu    = "1"
        }
        cpu_idle = true
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
}

resource "google_cloud_run_v2_job" "run_worker" {
  for_each = local.code_locations
  name     = "dagster-run-worker-${each.key}"

  location = local.region

  lifecycle {
    ignore_changes = [
      template[0].labels,
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }

  labels = {
    "application" = "dagster"
  }

  template {
    template {
      service_account = "dagster@cfarm-tech-${local.env}-apps.iam.gserviceaccount.com"

      max_retries = 0

      vpc_access {
        connector = data.terraform_remote_state.bootstrap_shared.outputs.vpc_access_connectors[local.region]
        egress    = "PRIVATE_RANGES_ONLY"
      }

      timeout = "86400s"

      containers {
        image = each.value.image

        env {
          name  = "DATABASE_HOST"
          value = data.terraform_remote_state.postgres_shared.outputs.db_instance_private_ip
        }

        env {
          name  = "DATABASE_USER"
          value = "dagster"
        }

        env {
          name  = "DATABASE_DBNAME"
          value = "dagster"
        }

        env {
          name  = "DATABASE_SCHEMA"
          value = "public"
        }

        env {
          name = "DATABASE_PASSWORD"
          value_source {
            secret_key_ref {
              secret  = module.webserver.sql_password_secret_id
              version = "latest"
            }
          }
        }

        resources {
          limits = {
            memory = each.value.run_worker_memory
            cpu    = each.value.run_worker_cpu
          }
        }
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "code_server_is_open" {
  for_each = google_cloud_run_v2_service.code_server
  name     = each.value.name
  location = each.value.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_job_iam_member" "webserver_can_execute_run_worker" {
  for_each = google_cloud_run_v2_job.run_worker
  name     = each.value.name
  location = each.value.location
  role     = "roles/run.admin"
  member   = "serviceAccount:${module.webserver.service_account_email}"
}

# For some reason, setting run.developer or even run.admin permissions at job level
# does not allow executions to be cancelled. So we need to set it at project level.
resource "google_project_iam_member" "webserver_can_execute_run_worker" {
  role    = "roles/run.developer"
  member  = "serviceAccount:${module.webserver.service_account_email}"
  project = local.project
}
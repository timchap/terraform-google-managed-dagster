# Project and Region
variable "project" {
  type = string
  description = "The GCP project ID"
}

variable "region" {
  type = string
  description = "The GCP region"
}

# Daemon Configuration
variable "daemon_zone" {
  type = string
  description = "The zone where the daemon will run"
}

variable "daemon_machine_type" {
  type    = string
  default = "e2-small"
  description = "The machine type for the daemon instance"
}

variable "daemon_image" {
  type = string
  description = "The image to use for the daemon instance"
}

variable "daemon_args" {
  type    = list(string)
  default = []
  description = "Arguments to pass to the daemon"
}

variable "daemon_command" {
  type        = list(string)
  description = "Entrypoint command to run in the daemon container"
  default = ["dagster", "daemon"]
}

variable "daemon_instance_name" {
  type        = string
  description = "Name of the daemon instance"
  default = "dagster-daemon"
}

# Database Configuration
variable "db_instance_name" {
  type        = string
  description = "Name of the database to connect to"
}

variable "db_instance_private_ip" {
  type        = string
  description = "Private IP of the database to connect to"
}

variable "db_database_name" {
  type        = string
  default     = "dagster"
  description = "Name of the database to create"
}

variable "db_user" {
  type        = string
  default     = "dagster"
  description = "Name of the database user to create"
}

variable "db_schema" {
  type        = string
  default     = "public"
  description = "Name of the database schema to use"
}

# Network Configuration
variable "vpc_connector_id" {
  type        = string
  description = "ID of the VPC connector to use for Cloud Run services and jobs"
}

variable "network" {
  type        = string
  description = "Name of the VPC to use for services, jobs, and daemon. Must be the same network as DB instance."
}

variable "subnetwork" {
  type        = string
  description = "Name of the subnet to use for services, jobs, and daemon. Must be the same subnet as DB instance."
}

# Webserver Configuration
variable "webserver_image" {
  type = string
  description = "The image to use for the webserver"
}

variable "webserver_args" {
  type    = list(string)
  default = ["--host", "0.0.0.0", "--port", "3000"]
  description = "Arguments to pass to the webserver"
}

variable "webserver_env" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
  description = "Environment variables for the webserver"
}

variable "webserver_env_secrets" {
  type = list(object({
    name      = string
    secret_id = string
  }))
  default = []
  description = "Environment variables for the webserver from secrets"
}

variable "webserver_port" {
  type    = number
  default = 3000
  description = "Port on which the webserver will run"
}

variable "webserver_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    cpu_idle          = bool
    startup_cpu_boost = bool
  })
  default = {
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
    cpu_idle          = true
    startup_cpu_boost = true
  }
  description = "Resources for the webserver"
}

variable "webserver_startup_probe" {
  type = object({
    initial_delay_seconds = number
    timeout_seconds       = number
    period_seconds        = number
    failure_threshold     = number
    http_path             = string
    http_port             = number
  })
  default = {
    initial_delay_seconds = 0
    timeout_seconds       = 10
    period_seconds        = 10
    failure_threshold     = 3
    http_path             = "/server_info"
    http_port             = 3000
  }
  description = "Startup probe configuration for the webserver"
}

variable "webserver_ingress" {
  type    = string
  default = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  description = "Ingress traffic setting for the webserver"
}

variable "webserver_min_instance_count" {
  type        = number
  default     = 0
  description = "Minimum number of instances to run for the webserver"
}

variable "webserver_max_instance_count" {
  type        = number
  default     = 1
  description = "Maximum number of instances to run for the webserver"
}

variable "webserver_service_name" {
  type        = string
  description = "Name of the webserver service"
  default = "dagster-webserver"
}

variable "webserver_command" {
  type        = list(string)
  description = "Entrypoint command to run in the webserver container"
  default = ["dagster-webserver"]
}

variable "webserver_max_instance_request_concurrency" {
  type    = number
  default = 80
  description = "Maximum number of requests a single webserver instance can handle at a time"
}

# Code location configuration
variable "code_server_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    cpu_idle = bool
  })
  default = {
    limits = {
      cpu    = "1"
      memory = "1Gi"
    }
    cpu_idle = true
  }
  description = "Resources for the code server"
}

variable "code_locations" {
  type = map(object({
    image = string
    run_worker_resources_limits = object({
      cpu    = string
      memory = string
    })
    module_name = string
    port        = number
  }))
  description = "Configuration for code locations"
}

variable "code_server_command" {
  type        = list(string)
  description = "Entrypoint command to run in the code server container"
  default = ["dagster", "api", "grpc"]
}

# Logging and Monitoring
variable "log_bucket" {
  type = string
  description = "GCS bucket for logs"
}

variable "log_bucket_retention_days" {
  type    = number
  default = 30
  description = "Retention period for logs in days"
}

variable "io_bucket" {
  type = string
  description = "GCS bucket for input/output"
}

# Service Accounts
variable "primary_service_account_name" {
  type        = string
  description = "Name of the primary service account to use for the webserver, daemon, and code servers"
  default = "dagster"
}

variable "run_worker_service_account_prefix" {
  type        = string
  description = "Prefix for the service account names for the run workers"
  default = "dagster-run-worker-"
}

# Run Worker Configuration
variable "run_worker_job_timeout_seconds" {
  type    = number
  default = 86400
  description = "Job timeout in seconds for run workers"
}

# Miscellaneous
variable "labels" {
  type = map(string)
  default = {
    application = "dagster"
  }
  description = "Labels to apply to resources"
}

variable "execution_environment" {
  type    = string
  default = "EXECUTION_ENVIRONMENT_GEN1"
  description = "Execution environment for all Cloud Run services"
}

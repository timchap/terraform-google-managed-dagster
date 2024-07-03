

resource "google_compute_instance" "daemon" {

  name    = var.daemon_instance_name
  project = var.project
  zone    = var.daemon_zone

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork
  }

  service_account {
    email  = google_service_account.primary.email
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible        = false
    provisioning_model = "STANDARD"
    automatic_restart  = true
  }

  machine_type = var.daemon_machine_type

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      size  = 20
    }
  }

  labels = var.labels

  metadata = {
    google-logging-enabled    = "true"

    # The container spec below is subject to change, see
    gce-container-declaration = <<EOF

spec:
  containers:
    - name: dagster-daemon
      image: '${var.daemon_image}'
      args: ${jsonencode(var.daemon_args)}
      env:
        - name: DATABASE_HOST
          value: "${var.db_instance_private_ip}"
        - name: DATABASE_USER
          value: "${var.db_user}"
        - name: DATABASE_DBNAME
          value: "${var.db_database_name}"
        - name: DATABASE_SCHEMA
          value: "${var.db_schema}"
        - name: DATABASE_PASSWORD_SECRET_NAME
          value: "${google_secret_manager_secret_version.dagster_db_password.id}"
        %{for name, svc in google_cloud_run_v2_service.code_server}
        - name: CODE_SERVER_HOST_${upper(name)}
          value: "${replace(svc.uri, "https://", "")}"
        %{endfor}
        - name: GOOGLE_CLOUD_PROJECT
          value: "${var.project}"
        - name: DAGSTER_LOGS_BUCKET
          value: "${google_storage_bucket.logs.name}"
      stdin: false
      tty: false
  restartPolicy: Always

EOF
  }

  metadata_startup_script = <<EOF
#! /bin/bash
set -e

echo "Installing Ops agent"
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo apt-get --allow-releaseinfo-change update
sudo apt-get install -y google-cloud-ops-agent
echo "Done."
EOF

  depends_on = [
    google_secret_manager_secret_iam_member.primary_can_get_secrets,
    google_artifact_registry_repository_iam_member.primary_can_read_artifacts
  ]
}

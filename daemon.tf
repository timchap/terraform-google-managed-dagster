
data "google_project" "this" {}

resource "google_compute_instance" "daemon" {

  name = "dagster-daemon"
  zone = "europe-west1-b"

  network_interface {
    network    = data.terraform_remote_state.bootstrap_shared.outputs["vpc_id"]
    subnetwork = data.terraform_remote_state.bootstrap_shared.outputs["subnets"]["europe-west1/primary"].self_link
  }

  service_account {
    email  = "dagster@cfarm-tech-${local.env}-apps.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible        = false
    provisioning_model = "STANDARD"
    automatic_restart  = true
  }

  machine_type = "e2-small"

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/family/cos-stable"
      size  = 20
    }
  }

  labels = {
    enable-ops-agent = "true"
    application      = "dagster",
  }

  metadata = {
    google-logging-enabled    = "true"
    gce-container-declaration = <<EOF

spec:
  containers:
    - name: dagster-daemon
      image: '${local.dagster_image}'
      args: ["daemon"]
      env:
        - name: DATABASE_HOST
          value: "${data.terraform_remote_state.postgres_shared.outputs.db_instance_private_ip}"
        - name: DATABASE_USER
          value: "dagster"
        - name: DATABASE_DBNAME
          value: "dagster"
        - name: DATABASE_SCHEMA
          value: "public"
        - name: DATABASE_PASSWORD_SECRET_NAME
          value: "${module.webserver.sql_password_secret_id}/versions/latest"
        - name: CODE_SERVER_HOST_CORE
          value: "${replace(google_cloud_run_v2_service.code_server["core"].uri, "https://", "")}"
        - name: GOOGLE_CLOUD_PROJECT
          value: "${data.google_project.this.project_id}"
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

}

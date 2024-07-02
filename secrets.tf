resource "google_secret_manager_secret" "sql_password" {
  for_each  = google_sql_user.app
  secret_id = "${var.db_instance_name}-${each.value.name}-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "sql_password" {
  for_each    = random_password.password
  secret      = google_secret_manager_secret.sql_password["default"].id
  secret_data = each.value.result
}
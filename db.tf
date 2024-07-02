
resource "google_sql_database" "app" {
  name     = var.db_database_name
  instance = var.db_instance_name
  project  = var.project
}

resource "google_sql_user" "app" {
  name     = var.db_user
  instance = var.db_instance_name
  password = random_password.password.result
  project  = var.project
}

resource "random_password" "password" {
  length  = 16
  special = true
}

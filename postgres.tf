
locals {
  db_name   = coalesce(var.db_name, var.app_name)
  create_db = var.db_instance_private_ip != null
}

resource "google_sql_database" "app" {
  for_each = toset(local.create_db ? ["default"] : [])
  name     = local.db_name
  instance = var.db_instance_name
}

resource "google_sql_user" "app" {
  for_each = random_password.password
  name     = local.db_name
  instance = var.db_instance_name
  password = each.value.result
}

resource "random_password" "password" {
  for_each = google_sql_database.app
  length   = 16
  special  = false
}

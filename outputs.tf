

output "sql_password_secret_id" {
  value = module.webserver.sql_password_secret_id
}

output "backend_service" {
  value = module.webserver.backend_service
}
output "url" {
  value = var.app.public ? "http://${local.host}" : "(interno) ${var.name}.${var.namespace}.svc:80"
}

output "image" {
  value = local.image
}

output "port" {
  value = local.port
}

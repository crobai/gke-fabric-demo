output "namespace" {
  value = var.tenant
}

output "app_name" {
  value = var.app_name
}

output "service_dns" {
  value = "${var.app_name}.${var.tenant}.svc:${var.http_port}"
}

output "replicas" {
  value = var.replicas
}

output "logs_hint" {
  value = "kubectl logs -n ${var.tenant} deploy/${var.app_name} -f | grep -E 'ALLOW|DENY|FAIL'"
}

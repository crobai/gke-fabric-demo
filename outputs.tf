output "subnet_name" {
  description = "Created GKE subnet name."
  value       = google_compute_subnetwork.gke.name
}

output "subnet_self_link" {
  description = "Created GKE subnet self link."
  value       = google_compute_subnetwork.gke.self_link
}

output "cluster_name" {
  description = "Autopilot cluster name."
  value       = module.cluster.name
}

output "cluster_endpoint" {
  description = "Autopilot cluster endpoint."
  value       = module.cluster.endpoint
}

output "get_credentials_command" {
  description = "Command to configure kubectl for this cluster."
  value       = "gcloud container clusters get-credentials ${module.cluster.name} --region ${var.region} --project ${var.project_id}"
}

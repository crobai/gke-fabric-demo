output "cluster_name" {
  description = "Shared Autopilot cluster name."
  value       = module.cluster.name
}

output "cluster_id" {
  description = "Fully qualified Autopilot cluster ID."
  value       = module.cluster.id
}

output "cluster_endpoint" {
  description = "Autopilot cluster endpoint."
  value       = module.cluster.endpoint
}

output "cluster_location" {
  description = "Autopilot cluster location (region)."
  value       = module.cluster.location
}

output "fleet_host_project" {
  description = "Fleet host project (one fleet per project; PoC = same as cluster project)."
  value       = local.fleet_enabled ? local.fleet_host_project : null
}

output "fleet_console_url" {
  description = "GCP Console path to verify fleet membership (Phase B)."
  value = local.fleet_enabled ? (
    "https://console.cloud.google.com/kubernetes/clusters/details/${var.region}/${module.cluster.name}/details?project=${local.fleet_host_project}"
  ) : null
}

output "fleet_membership_hint" {
  description = "How to verify the cluster is a fleet member after apply."
  value = local.fleet_enabled ? (
    "gcloud container fleet memberships list --project=${local.fleet_host_project}"
  ) : null
}

output "get_credentials_command" {
  description = "Configure kubectl for this cluster (demo / platform scripts)."
  value       = "gcloud container clusters get-credentials ${module.cluster.name} --region ${var.region} --project ${var.project_id}"
}

output "subnet_name" {
  description = "Created GKE subnet name."
  value       = google_compute_subnetwork.gke.name
}

output "subnet_self_link" {
  description = "Created GKE subnet self link."
  value       = google_compute_subnetwork.gke.self_link
}

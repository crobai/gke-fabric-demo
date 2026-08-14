output "cluster_name" {
  description = "Shared Standard cluster name."
  value       = module.cluster.name
}

output "cluster_id" {
  description = "Fully qualified Standard cluster ID."
  value       = module.cluster.id
}

output "cluster_endpoint" {
  description = "Cluster IP endpoint (may be private-only; prefer DNS)."
  value       = module.cluster.endpoint
}

output "cluster_dns_endpoint" {
  description = "Control plane DNS endpoint (operators / Terraform)."
  value       = module.cluster.dns_endpoint
}

output "cluster_location" {
  description = "Standard cluster location (region)."
  value       = module.cluster.location
}

output "node_pool_name" {
  description = "Managed node pool name."
  value       = module.nodepool.name
}

output "node_pool_machine_type" {
  description = "Node pool machine type (resource / size-class knob)."
  value       = local.node_pool_machine_type
}

output "max_pods_per_node" {
  description = "Max pods per node (density knob)."
  value       = local.node_pool_max_pods
}

output "node_pool_autoscaling" {
  description = "Node pool autoscaling bounds (elasticity knob)."
  value = {
    min_nodes = local.node_pool_min_nodes
    max_nodes = local.node_pool_max_nodes
  }
}

output "fleet_host_project" {
  description = "Fleet host project (one fleet per project; PoC = same as cluster project)."
  value       = local.fleet_enabled ? local.fleet_host_project : null
}

output "fleet_console_url" {
  description = "GCP Console path to verify fleet membership."
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
  description = "Configure kubectl for this cluster (DNS endpoint)."
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

output "capacity_knobs_hint" {
  description = "How to play with resources / density / autoscaling."
  value       = "Edit terraform.tfvars standard{} (machine_type, max_pods_per_node, min/max_nodes) then make platform-up. Or: make platform-nodes | platform-scale-up | platform-scale-down"
}

output "next_plane_hint" {
  description = "Next IDP plane after platform capacity demos (deferred)."
  value       = "make guardrails-up  # after platform playground"
}

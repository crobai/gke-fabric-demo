locals {
  fleet_enabled      = try(var.fleet.enabled, true)
  fleet_host_project = coalesce(try(var.fleet.host_project, null), var.project_id)

  cluster_labels = {
    environment = "dev"
    managed-by  = "terraform"
    role      = "shared-workload"
    idp-plane = "platform"
  }
}

locals {
  fleet_enabled      = try(var.fleet.enabled, true)
  fleet_host_project = coalesce(try(var.fleet.host_project, null), var.project_id)

  private_nodes = try(var.standard.access.private_nodes, true)
  dns_endpoint  = try(var.standard.access.dns_endpoint, true)

  max_pods_per_node = try(var.standard.max_pods_per_node, 32)
  node_pool_max_pods = coalesce(
    try(var.standard.node_pool.max_pods_per_node, null),
    local.max_pods_per_node
  )

  node_pool_name         = try(var.standard.node_pool.name, "default")
  node_pool_machine_type = try(var.standard.node_pool.machine_type, "e2-standard-2")
  node_pool_disk_type    = try(var.standard.node_pool.disk_type, "pd-balanced")
  node_pool_disk_size_gb = try(var.standard.node_pool.disk_size_gb, 30)
  node_pool_min_nodes    = try(var.standard.node_pool.min_nodes, 1)
  node_pool_max_nodes    = try(var.standard.node_pool.max_nodes, 3)

  node_locations = try(var.standard.node_locations, ["europe-west1-b"])

  cluster_labels = {
    environment = "dev"
    managed-by  = "terraform-fabric"
    role        = "shared-workload"
    idp-plane   = "platform"
    flavor      = "standard"
  }
}

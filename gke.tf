# Standard GKE via Fabric modules (IDP catalog flavor).
# Network approximation: project VPC + private nodes + DNS endpoint (not Shared VPC / LZ).

module "cluster" {
  source = "./fabric/modules/gke-cluster-standard"

  project_id          = var.project_id
  name                = var.cluster_name
  location            = var.region
  node_locations      = local.node_locations
  release_channel     = var.release_channel
  deletion_protection = false
  max_pods_per_node   = local.max_pods_per_node
  labels              = local.cluster_labels

  fleet_project = local.fleet_enabled ? local.fleet_host_project : null

  access_config = {
    private_nodes = local.private_nodes
    dns_access = local.dns_endpoint ? {
      allow_external_traffic = true
      } : {
      allow_external_traffic = false
    }
    # Omit ip_access → control plane IP endpoint disabled; operators use DNS.
  }

  enable_features = {
    dataplane_v2        = try(var.standard.dataplane_v2, true)
    fqdn_network_policy = try(var.standard.dataplane_v2, true)
  }

  vpc_config = {
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.gke.self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }

  depends_on = [
    google_project_service.required,
    google_compute_router_nat.gke,
  ]
}

module "nodepool" {
  source = "./fabric/modules/gke-nodepool"

  project_id   = var.project_id
  cluster_name = module.cluster.name
  cluster_id   = module.cluster.id
  location     = module.cluster.location
  name         = local.node_pool_name

  max_pods_per_node = local.node_pool_max_pods
  labels            = local.cluster_labels

  node_config = {
    machine_type = local.node_pool_machine_type
    boot_disk = {
      size_gb = local.node_pool_disk_size_gb
      type    = local.node_pool_disk_type
    }
  }

  node_count = {
    initial = local.node_pool_min_nodes
  }

  nodepool_config = {
    autoscaling = {
      # Total across zones (safe if node_locations grows later).
      use_total_nodes = true
      min_node_count  = local.node_pool_min_nodes
      max_node_count  = local.node_pool_max_nodes
    }
    management = {
      auto_repair  = true
      auto_upgrade = true
    }
  }

  service_account = {
    create = true
    email  = "${var.cluster_name}-nodes"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  depends_on = [module.cluster]
}

# Minimal node identity for logging/monitoring (custom node SA).
resource "google_project_iam_member" "nodepool_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${module.nodepool.service_account_email}"
}

resource "google_project_iam_member" "nodepool_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${module.nodepool.service_account_email}"
}

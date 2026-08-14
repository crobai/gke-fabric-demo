project_id   = "roberto-gke"
region       = "europe-west1"
cluster_name = "gke-fabric-demo"

fleet = {
  enabled = true
}

# IDP catalog-shaped Standard flavor (Fabric modules underneath).
# Network approximation: project VPC + private nodes + DNS endpoint.
standard = {
  dataplane_v2      = true
  max_pods_per_node = 32
  node_locations    = ["europe-west1-b"]

  access = {
    private_nodes = true
    dns_endpoint  = true
  }

  node_pool = {
    name         = "default"
    machine_type = "e2-standard-2" # was e2-medium; more headroom for system pods + scale demos
    disk_type    = "pd-balanced"
    disk_size_gb = 30
    min_nodes    = 1
    max_nodes    = 3 # demo headroom; idle can set 2
  }
}

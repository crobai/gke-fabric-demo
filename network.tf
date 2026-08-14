data "google_compute_network" "default" {
  name    = var.network_name
  project = var.project_id

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "gke" {
  name          = var.subnet_name
  project       = var.project_id
  region        = var.region
  network       = data.google_compute_network.default.id
  ip_cidr_range = var.subnet_cidr

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }

  private_ip_google_access = true

  depends_on = [google_project_service.required]
}

# Private nodes need egress for image pulls / package mirrors (project-VPC approximation of LZ NAT).
resource "google_compute_router" "gke" {
  name    = "${var.cluster_name}-router"
  project = var.project_id
  region  = var.region
  network = data.google_compute_network.default.id

  depends_on = [google_project_service.required]
}

resource "google_compute_router_nat" "gke" {
  name                               = "${var.cluster_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.gke.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.gke.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = false
    filter = "ALL"
  }
}

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

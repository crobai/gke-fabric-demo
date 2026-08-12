module "cluster" {
  source = "./fabric/modules/gke-cluster-autopilot"

  project_id        = var.project_id
  name              = var.cluster_name
  location          = var.region
  release_channel   = "REGULAR"
  deletion_protection = false

  vpc_config = {
    network    = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.gke.self_link
    secondary_range_names = {
      pods     = "pods"
      services = "services"
    }
  }

  depends_on = [google_project_service.required]
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Required by fabric/modules/gke-hub (memberships and features use google-beta).
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

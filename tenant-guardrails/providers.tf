provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

data "google_container_cluster" "platform" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.platform.endpoint}"
  token = data.google_client_config.default.access_token
}

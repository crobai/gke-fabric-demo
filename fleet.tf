module "hub" {
  source = "./fabric/modules/gke-hub"
  count  = local.fleet_enabled ? 1 : 0

  project_id = local.fleet_host_project
  location   = var.region

  # Membership owned by fleet_project on the Standard cluster module.
  clusters = {}

  features = {
    appdevexperience             = false
    configmanagement             = false
    identityservice              = false
    multiclusteringress          = null
    multiclusterservicediscovery = false
    policycontroller             = false
    servicemesh                  = false
  }

  depends_on = [
    google_project_service.required,
    module.cluster,
  ]
}

project_id   = "roberto-gke"
region       = "europe-west1"
cluster_name = "gke-fabric-demo"

tenants = {
  t1-front = {
    team_principals = ["user:roberto.comsa@esolutions.ro"]
    quota = {
      pods   = "2"
      cpu    = "2"
      memory = "4Gi"
    }
    allow_egress = [
      { namespace = "t2-back", port = 8080 }
    ]
    allow_ingress_from = []
  }

  t2-back = {
    team_principals = []
    quota = {
      pods   = "4"
      cpu    = "2"
      memory = "4Gi"
    }
    allow_egress = [
      { namespace = "t3-db", port = 8080 }
    ]
    allow_ingress_from = ["t1-front"]
  }

  t3-db = {
    team_principals = []
    quota = {
      pods   = "4"
      cpu    = "2"
      memory = "4Gi"
    }
    allow_egress       = []
    allow_ingress_from = ["t2-back"]
  }
}

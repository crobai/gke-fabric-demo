locals {
  tenant_subjects = {
    for ns, t in var.tenants : ns => [
      for p in t.team_principals : {
        kind = startswith(lower(p), "group:") ? "Group" : "User"
        name = length(split(":", p)) > 1 ? split(":", p)[1] : p
      }
    ]
  }

  tenants_with_principals = {
    for ns, t in var.tenants : ns => t
    if length(t.team_principals) > 0
  }
}

resource "kubernetes_namespace_v1" "tenant" {
  for_each = var.tenants

  metadata {
    name = each.key
    labels = {
      "idp.demo/tenant"     = each.key
      "idp.demo/managed-by" = "portal-power-user"
      "idp.demo/plane"      = "tenant-guardrails"
    }
  }
}

resource "kubernetes_resource_quota_v1" "tenant" {
  for_each = var.tenants

  metadata {
    name      = "tenant-quota"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  spec {
    hard = {
      pods              = each.value.quota.pods
      "requests.cpu"    = each.value.quota.cpu
      "requests.memory" = each.value.quota.memory
      "limits.cpu"      = each.value.quota.cpu
      "limits.memory"   = each.value.quota.memory
    }
  }
}

resource "kubernetes_limit_range_v1" "tenant" {
  for_each = var.tenants

  metadata {
    name      = "tenant-limits"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "500m"
        memory = "512Mi"
      }
      default_request = {
        cpu    = "100m"
        memory = "128Mi"
      }
      min = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
  }
}

resource "kubernetes_role_binding_v1" "tenant_edit" {
  for_each = local.tenants_with_principals

  metadata {
    name      = "tenant-edit"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "edit"
  }

  dynamic "subject" {
    for_each = local.tenant_subjects[each.key]
    content {
      kind      = subject.value.kind
      name      = subject.value.name
      api_group = "rbac.authorization.k8s.io"
    }
  }
}

resource "kubernetes_network_policy_v1" "tenant" {
  for_each = var.tenants

  metadata {
    name      = "tenant-isolation"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {}
      }
    }

    dynamic "ingress" {
      for_each = each.value.allow_ingress_from
      content {
        from {
          namespace_selector {
            match_labels = {
              "kubernetes.io/metadata.name" = ingress.value
            }
          }
        }
        ports {
          port     = tostring(var.http_port)
          protocol = "TCP"
        }
      }
    }

    egress {
      to {
        pod_selector {}
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
        pod_selector {
          match_labels = {
            "k8s-app" = "kube-dns"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    dynamic "egress" {
      for_each = length(var.dns_egress_cidrs) > 0 ? [""] : []
      content {
        dynamic "to" {
          for_each = var.dns_egress_cidrs
          content {
            ip_block {
              cidr = to.value
            }
          }
        }
        ports {
          port     = "53"
          protocol = "UDP"
        }
        ports {
          port     = "53"
          protocol = "TCP"
        }
      }
    }

    dynamic "egress" {
      for_each = each.value.allow_egress
      content {
        to {
          namespace_selector {
            match_labels = {
              "kubernetes.io/metadata.name" = egress.value.namespace
            }
          }
        }
        ports {
          port     = tostring(coalesce(egress.value.port, var.http_port))
          protocol = "TCP"
        }
      }
    }
  }
}

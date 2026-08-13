output "tenant_namespaces" {
  value = sort(keys(kubernetes_namespace_v1.tenant))
}

output "tenant_guardrails" {
  value = {
    for ns, t in var.tenants : ns => {
      principals         = t.team_principals
      pods_quota         = t.quota.pods
      allow_egress_to    = [for e in t.allow_egress : e.namespace]
      allow_ingress_from = t.allow_ingress_from
    }
  }
}

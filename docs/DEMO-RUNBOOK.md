# Client demo runbook

~15–25 minutes. Makefile / `scripts/` stand in for the portal.

**Platform first:** Fabric **Standard** + one node pool (Confluence default). Guardrails / tenant apps after the capacity story.

## 0. Preconditions

```bash
gcloud config set project roberto-gke
make platform-up   # if cluster not up yet
$(terraform output -raw get_credentials_command)
```

---

## 1. Architecture (talk track)

Three planes:

1. **Platform** — shared **Standard** cluster + one governed node pool + fleet  
   - Approximation: **project VPC + private nodes + DNS endpoint + Cloud NAT** (prod = Shared VPC / LZ private floor)  
2. **Portal power-user** (SRE / tech lead) — namespaces, quota, RBAC, NetworkPolicy  
3. **Tenant (dev)** — Deployments / Services only inside their namespace  

---

## 2. Platform — Standard runtime + Hub

```bash
terraform output cluster_name node_pool_machine_type max_pods_per_node node_pool_autoscaling
terraform output -raw cluster_dns_endpoint
terraform output fleet_membership_hint
# or open:
terraform output -raw fleet_console_url
```

Show in Console: Standard mode, private nodes, one pool, machine type, autoscaling, fleet member.

### 2b. Capacity playground (platform-owned)

Show allocatable first, then both autoscaler behaviors:

```bash
make platform-nodes

# 1) Oversize request — platform correctly refuses to scale
make platform-scale-up-blocked
# Console: "Can't scale up … failing scheduling predicate"
# Talk: catalog machine type must fit the pod; CA will not grow uselessly
make platform-scale-down

# 2) Fitting request — pack the pool, CA adds a node
make platform-scale-up
# Watch nodes grow (min→… within max)
make platform-scale-down
```

Or edit `terraform.tfvars` → `standard{}` (`machine_type`, `max_pods_per_node`, `min_nodes` / `max_nodes`) and `make platform-up`.

---

## 3. Power-user — guardrails

```bash
make guardrails-up
kubectl get ns t1-front t2-back t3-db
kubectl get resourcequota,networkpolicy,rolebinding -n t1-front
kubectl get resourcequota,networkpolicy,rolebinding -n t2-back
kubectl get resourcequota,networkpolicy,rolebinding -n t3-db
```

Narrate: platform catalog + power-user onboarding; developers do not edit these.

---

## 4. Developer — deploy probe apps

```bash
make tenant-deploy-all
```

Order is db → back → front so DNS peers exist.

---

## 5. NetworkPolicy — live ALLOW / DENY logs

```bash
make demo-logs TENANT=t1-front
# follow: make demo-logs TENANT=t1-front FOLLOW=1
```

Expect:

- `ALLOW ok http://back.t2-back.svc:8080/health`
- `DENY timeout/fail http://db.t3-db.svc:8080/health`

Optional: `make demo-logs TENANT=t2-back` (allow db, deny front).

---

## 6. RBAC — t1 cannot deploy into t2

```bash
make demo-rbac
# or: make demo-rbac AS=roberto.comsa@esolutions.ro
```

Expect: **yes** on `t1-front`, **no** / Forbidden on `t2-back`.

---

## 7. Quota — scale front 2 → 3 fails

```bash
make demo-quota
```

Expect FailedCreate / exceeded `tenant-quota` (`pods=2`). Script restores replicas to 2.

Portal-shaped alternative (leaves Terraform wanting 3 until you re-apply with 2):

```bash
make tenant-deploy TENANT=t1-front REPLICAS=3
```

---

## 8. Close

Map to a real IDP: Backstage power-user form → `tenant-guardrails`; developer form → `tenant-apps` / Argo. Same params, different UI.

**Aligned with Confluence:** Standard shared runtime + namespace guardrails.  
**Approximated:** project VPC + DNS endpoint (not full Shared VPC / private IP CP).  
**Out of scope:** Workload Identity, Config Sync, multi-cluster.

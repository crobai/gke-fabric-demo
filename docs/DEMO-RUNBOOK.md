# Client demo runbook (Phase E)

~15–20 minutes. Makefile / `scripts/` stand in for the portal.

## 0. Preconditions

```bash
gcloud config set project roberto-gke
$(terraform output -raw get_credentials_command)
kubectl get ns t1-front t2-back t3-db
```

If the cluster or guardrails are missing: `make platform-up` then `make guardrails-up`.

---

## 1. Architecture (talk track)

Three planes:

1. **Platform** — shared Autopilot + fleet  
2. **Portal power-user** (SRE / tech lead) — namespaces, quota, RBAC, NetworkPolicy  
3. **Tenant (dev)** — Deployments / Services only inside their namespace  

---

## 2. Platform — Hub membership

```bash
terraform output fleet_membership_hint
# or open:
terraform output -raw fleet_console_url
```

Show the cluster listed as a fleet member in Console / `gcloud container fleet memberships list`.

---

## 3. Power-user — guardrails already applied

```bash
make guardrails-up   # no-op if already applied
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

## 5. NetworkPolicy — live ALLOW / DENY logs (E1)

```bash
make demo-logs TENANT=t1-front
# follow: make demo-logs TENANT=t1-front FOLLOW=1
```

Expect:

- `ALLOW ok http://back.t2-back.svc:8080/health`
- `DENY timeout/fail http://db.t3-db.svc:8080/health`

Optional: `make demo-logs TENANT=t2-back` (allow db, deny front).

---

## 6. RBAC — t1 cannot deploy into t2 (E2)

```bash
make demo-rbac
# or: make demo-rbac AS=roberto.comsa@esolutions.ro
```

Expect: **yes** on `t1-front`, **no** / Forbidden on `t2-back`.

---

## 7. Quota — scale front 2 → 3 fails (E3)

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

Optional stretch (Phase F): Workload Identity, Config Sync.

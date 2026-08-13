# gke-fabric-demo

PoC: simulate an IDP on GKE with [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules.

## Three planes

| Plane | Who | Directory | Command |
|-------|-----|-----------|---------|
| **Platform** | Platform engineers | repo root | `make platform-up` |
| **Portal power-user** | Client SRE / tech lead | [`tenant-guardrails/`](tenant-guardrails/) | `make guardrails-up` |
| **Tenant (dev)** | Application developers | [`tenant-apps/`](tenant-apps/) (Phase D) | `make tenant-deploy` |

Platform owns the shared Autopilot + fleet. Power-users onboard namespaces (quota / RBAC / netpol) via the portal. Developers only deploy apps into their namespace.

## Quick start

```bash
# 1) Platform — cluster + fleet
make platform-up

# 2) Portal power-user — namespaces + guardrails
make guardrails-up

# 3) Tenant (dev) — probe apps (Phase D — not yet)
# make tenant-deploy TENANT=t1-front REPLICAS=2
```

```bash
$(terraform output -raw get_credentials_command)
kubectl get ns,resourcequota,networkpolicy,rolebinding -A | grep -E 't1-front|t2-back|t3-db|NAME'
```

## Design docs

- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) — implementation checklist + actor model
- [docs/IDP-GKE-POC-FLEETS-TENANTS.md](docs/IDP-GKE-POC-FLEETS-TENANTS.md) — locked PoC scope + client demo
- [docs/IDP-GKE-CONSIDERATIONS.md](docs/IDP-GKE-CONSIDERATIONS.md) — flavors, fabric modules

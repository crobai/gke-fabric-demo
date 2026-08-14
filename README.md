# gke-fabric-demo

PoC: simulate an IDP on GKE with [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules.

## Three planes

| Plane | Who | Directory | Command |
|-------|-----|-----------|---------|
| **Platform** | Platform engineers | repo root | `make platform-up` |
| **Portal power-user** | Client SRE / tech lead | [`tenant-guardrails/`](tenant-guardrails/) | `make guardrails-up` |
| **Tenant (dev)** | Application developers | [`tenant-apps/`](tenant-apps/) | `make tenant-deploy` |

## Quick start

```bash
make platform-up
make guardrails-up
make tenant-deploy-all

$(terraform output -raw get_credentials_command)
make tenant-logs TENANT=t1-front
```

Expect front logs: `ALLOW ok` to back, `DENY timeout/fail` to db.

### Negative demos (client showcase)

```bash
# RBAC — user bound only to t1-front
make tenant-can-i TENANT=t1-front AS=roberto.comsa@esolutions.ro   # yes
make tenant-can-i TENANT=t2-back AS=roberto.comsa@esolutions.ro    # no

# Quota — t1-front pods=2
make tenant-deploy TENANT=t1-front REPLICAS=3                     # exceeded quota
```

## Design docs

- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) — implementation checklist + actor model
- [docs/IDP-GKE-POC-FLEETS-TENANTS.md](docs/IDP-GKE-POC-FLEETS-TENANTS.md) — locked PoC scope + client demo
- [docs/IDP-GKE-CONSIDERATIONS.md](docs/IDP-GKE-CONSIDERATIONS.md) — flavors, fabric modules

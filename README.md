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
make demo-logs TENANT=t1-front
```

Expect front logs: `ALLOW ok` to back, `DENY timeout/fail` to db.

### Negative demos (Phase E)

```bash
make demo-rbac     # t1 yes / t2 Forbidden
make demo-quota    # scale front 2→3 exceeds pods=2, then restore
```

Full client order: [docs/DEMO-RUNBOOK.md](docs/DEMO-RUNBOOK.md).

## Design docs

- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) — implementation checklist + actor model
- [docs/DEMO-RUNBOOK.md](docs/DEMO-RUNBOOK.md) — client demo script (Phase E)
- [docs/IDP-GKE-POC-FLEETS-TENANTS.md](docs/IDP-GKE-POC-FLEETS-TENANTS.md) — locked PoC scope + client demo
- [docs/IDP-GKE-CONSIDERATIONS.md](docs/IDP-GKE-CONSIDERATIONS.md) — flavors, fabric modules

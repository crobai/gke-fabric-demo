# gke-fabric-demo

PoC: simulate an IDP on GKE with [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules.

**Scope complete through Phase E** (platform → power-user guardrails → tenant apps → demo scripts). No further phases in this repo.

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

### Negative demos

```bash
make demo-rbac     # t1 yes / t2 Forbidden
make demo-quota    # scale front 2→3 exceeds pods=2, then restore
```

Full client order: [docs/DEMO-RUNBOOK.md](docs/DEMO-RUNBOOK.md).

## Design docs

- [docs/DEMO-RUNBOOK.md](docs/DEMO-RUNBOOK.md) — client demo script
- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) — implementation checklist (A–E done)
- [docs/IDP-GKE-POC-FLEETS-TENANTS.md](docs/IDP-GKE-POC-FLEETS-TENANTS.md) — locked PoC scope
- [docs/IDP-GKE-CONSIDERATIONS.md](docs/IDP-GKE-CONSIDERATIONS.md) — broader design notes (not PoC backlog)

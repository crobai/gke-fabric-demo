# gke-fabric-demo

PoC: simulate an IDP on GKE with [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules.

**Platform runtime:** Fabric **Standard** (`gke-cluster-standard` + one `gke-nodepool`) — project VPC + **private nodes** + **DNS endpoint** (LZ Shared VPC approximation). Guardrails / tenant apps are secondary after the platform capacity playground.

## Three planes

| Plane | Who | Directory | Command |
|-------|-----|-----------|---------|
| **Platform** | Platform engineers | repo root | `make platform-up` |
| **Portal power-user** | Client SRE / tech lead | [`tenant-guardrails/`](tenant-guardrails/) | `make guardrails-up` |
| **Tenant (dev)** | Application developers | [`tenant-apps/`](tenant-apps/) | `make tenant-deploy` |

## Quick start (platform first)

```bash
make platform-up
$(terraform output -raw get_credentials_command)

# Capacity playground — resources / max pods / autoscaling
make platform-nodes
make platform-scale-up-blocked   # CA refuses (request > node)
make platform-scale-down
make platform-scale-up           # CA adds a node
make platform-scale-down

# Later: same tenancy on this cluster
make guardrails-up
make tenant-deploy-all
make demo-logs TENANT=t1-front
```

Edit `terraform.tfvars` → `standard{}` to change `machine_type`, `max_pods_per_node`, or pool `min_nodes` / `max_nodes`, then `make platform-up`.

### Negative demos (after guardrails)

```bash
make demo-rbac     # t1 yes / t2 Forbidden
make demo-quota    # scale front 2→3 exceeds pods=2, then restore
```

Full client order: [docs/DEMO-RUNBOOK.md](docs/DEMO-RUNBOOK.md).

## Design docs

- [docs/DEMO-RUNBOOK.md](docs/DEMO-RUNBOOK.md) — client demo script (platform Standard first)
- [docs/IDP-GKE-POC-FLEETS-TENANTS.md](docs/IDP-GKE-POC-FLEETS-TENANTS.md) — locked PoC scope vs Confluence
- [docs/IDP-GKE-CONSIDERATIONS.md](docs/IDP-GKE-CONSIDERATIONS.md) — flavor catalog / trade-offs
- [STANDARD_GKE_PLAN.md](STANDARD_GKE_PLAN.md) — Standard cutover / capacity playground (local)

# gke-fabric-demo

PoC: simulate an Internal Developer Platform (IDP) on GKE using [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules — shared Autopilot cluster, one fleet, namespace tenancy with platform-owned guardrails.

## Current scope (Phase A)

Platform foundation in this root module:

- Required APIs (`container`, `compute`, `gkehub`, `gkeconnect`)
- VPC-native subnet on the project VPC
- Shared Autopilot cluster (`fabric/modules/gke-cluster-autopilot`) with `fleet_project` registration
- Thin `fabric/modules/gke-hub` wiring (no Config Sync / MCS / Mesh yet)

Next: fleet verification (Phase B), then tenant namespaces + RBAC / quotas / NetworkPolicy (Phase C).

## Quick start

```bash
terraform init
terraform plan
terraform apply
terraform output get_credentials_command
terraform output fleet_membership_hint
```

## Design docs

- [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) — implementation checklist
- [docs/IDP-GKE-POC-FLEETS-TENANTS.md](docs/IDP-GKE-POC-FLEETS-TENANTS.md) — locked PoC scope + client demo
- [docs/IDP-GKE-CONSIDERATIONS.md](docs/IDP-GKE-CONSIDERATIONS.md) — flavors, fabric modules, decision map

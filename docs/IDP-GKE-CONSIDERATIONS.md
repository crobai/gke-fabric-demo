# IDP GKE considerations (POC)

What to take into account when deploying **multiple GKE cluster flavors** for an Internal Developer Platform (IDP), using [Cloud Foundation Fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric) modules.

This document is **background / planning only** (flavors, trade-offs). It is **not** an active backlog for this repo.

The implemented PoC stops at **Phase E** — see [DEMO-RUNBOOK.md](DEMO-RUNBOOK.md) and [../DEVELOPMENT_PLAN.md](../DEVELOPMENT_PLAN.md). Workload Identity, Config Sync, and multi-cluster stretch items below were **not** built.

## Scope (assumed)

Both sides of an IDP on GKE:

1. **Platform clusters** — host the IDP control plane (portal, APIs, controllers, often CI runners).
2. **Tenant / workload clusters** — flavors the platform offers to application teams.

Adjust or drop a section if your POC only covers one side.

---

## 1. Current POC baseline

| Item | Today in this repo |
|------|--------------------|
| Cluster mode | Autopilot via `fabric/modules/gke-cluster-autopilot` |
| Fabric pin | [v57.0.0](../fabric/FABRIC_VERSION) |
| Vendored modules | autopilot, standard, nodepool, hub |
| Networking | Subnet + pods/services secondary ranges on the `default` VPC |
| State | Local Terraform state |
| Multi-flavor switch | Not implemented (single Autopilot path in `gke.tf`) |

**Gaps vs a production-shaped IDP:**

- No Fleet / `gke-hub` registration
- No private control plane / private nodes pattern
- No Shared VPC
- No catalog of cluster flavors driven by variables
- No remote state or teammate isolation story beyond ad-hoc tfvars

This matches **path B** from earlier exploration: use fabric **modules** in a demo project, not full Fabric FAST org stages.

---

## 2. Decision map — what an IDP must choose per cluster

```mermaid
flowchart TD
  idpNeeds[IDP_need] --> role[Cluster_role]
  role --> platform[Platform_control_plane]
  role --> tenant[Tenant_workload]
  platform --> mode[Autopilot_vs_Standard]
  tenant --> mode
  mode --> network[Network_model]
  mode --> identity[Identity_and_tenancy]
  mode --> ops[Ops_and_upgrades]
  network --> fleet[Fleet_registration]
  identity --> fleet
```

Every cluster the IDP creates (or that hosts the IDP) should have explicit answers for the areas below.

### Mode (Autopilot vs Standard)

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Default tenant offering is usually Autopilot (less ops). Standard is needed for custom node shapes, some DaemonSets, GPUs, or privileged/host patterns Autopilot restricts. | `gke-cluster-autopilot` vs `gke-cluster-standard` + `gke-nodepool` | [Choose cluster mode](https://cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode), [Autopilot overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview) |

### Topology and upgrades

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Regional clusters for HA of platform/tenant prod; release channel affects how fast CVE/version rolls land. | `location`, `release_channel`, `maintenance_config` | [Release channels](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels) |

### Network

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| VPC-native Pod/Service ranges are mandatory. Shared VPC is typical in enterprises; demo uses project VPC. Private clusters change how the IDP/agents reach the API server. | `vpc_config` (network, subnetwork, secondary ranges); `access_config` (private nodes, authorized ranges) | [VPC-native clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips), [Private clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters) |

CIDR planning must avoid overlaps when many teams get a cluster on the same VPC (see earlier teammate subnet discussion).

### Identity and tenancy

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Workload Identity is the default GCP↔K8s auth path. Tenancy model drives blast radius: **namespace-per-team** on a shared cluster vs **cluster-per-team** (or per-env). | Autopilot WI defaults; Standard `workload_identity` / node metadata; optional `fleet_project` | [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) |

### Security

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Platform clusters often need stricter defaults (Binary Auth, shielded nodes, CMEK, restricted egress). Tenant flavors may trade strictness for flexibility. | `enable_features` (e.g. binary_authorization, database_encryption), node shielded settings on Standard/nodepool | [Harden your cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster) |

### Multicluster (Fleet)

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| IDPs usually manage many clusters: shared policy (Config Sync), inventory, multi-cluster services. Fleet is the GKE grouping boundary. | `gke-hub` module; `fleet_project` on cluster modules | [Fleet concepts](https://cloud.google.com/kubernetes-engine/fleet-management/docs/fleet-concepts), [Config Sync](https://cloud.google.com/kubernetes-engine/enterprise/config-sync/docs/overview) |

### Observability

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Platform needs consistent logs/metrics across flavors for SLOs and tenant support. | `logging_config`, `monitoring_config` (Autopilot baselines differ from Standard) | [GKE logging](https://cloud.google.com/stackdriver/docs/solutions/gke/installing), [GKE metrics](https://cloud.google.com/stackdriver/docs/solutions/gke/managing-metrics) |

### Cost and sizing

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Autopilot bills largely from Pod requests (defaults apply if unset). Standard bills node pools (idle cost even with no apps). IDP catalog should set expectations per flavor. | Autopilot: workload requests; Standard: `gke-nodepool` machine/disk/autoscaling | [Autopilot resource requests](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests) |

### IaC and platform operations

| Why it matters for IDP | Fabric knobs | Docs |
|------------------------|--------------|------|
| Each provisioned cluster needs clear state ownership (remote state per tenant or per request). POC can stay module-based; full FAST is for org landing zones later. | Root module wrappers; remote backend (later) | [Fabric FAST](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/fast/README.md) |

### IDP product surface

The portal/API should expose a **flavor ID** plus a small input set (project, region, network refs, owner/team, optional GPU size). Terraform (or a pipeline) maps flavor → fabric modules + defaults. Keep human-facing choices few; hide fabric variable sprawl behind the flavor.

---

## 3. Proposed cluster flavor catalog (POC target)

Implement later as thin wrappers / `flavor` switches—not in this doc phase.

| Flavor ID | Mode | Typical IDP use | Fabric modules | Minimum inputs | Fleet |
|-----------|------|-----------------|----------------|----------------|-------|
| `platform-autopilot` | Autopilot | Portal, APIs, lightweight controllers | `gke-cluster-autopilot` | project, region, VPC/subnet (+ secondary ranges) | Recommended |
| `tenant-autopilot` | Autopilot | Default app-team envs | `gke-cluster-autopilot` | Same + unique name/CIDRs per tenant | Recommended |
| `tenant-standard` | Standard | Custom machines, DaemonSets, privileged/host needs | `gke-cluster-standard` + `gke-nodepool` | Above + machine type, min/max nodes | Optional |
| `tenant-standard-gpu` | Standard + GPU pool | ML / inference (stretch) | `gke-cluster-standard` + GPU `gke-nodepool` | Above + accelerator type/count, drivers | Optional |
| `platform-cicd` | Autopilot or Standard | Isolated runners / build agents | autopilot **or** standard + nodepool | Prefer network isolation from prod tenants | Optional |

### What the IDP should collect from the user (per request)

- **Always:** team/owner id, environment (dev/stage/prod), region, flavor ID.
- **Network:** host project + VPC + subnet (or “use platform default network factory”).
- **Standard only:** node size class (or fixed SKUs in the catalog), autoscaling bounds.
- **GPU only:** GPU type/count, optional spot.
- **Never dump raw fabric `variables.tf` into the UI** — map UI fields → module inputs in code.

---

## 4. Fabric module mapping

Vendored in this repo @ v57.0.0:

| Module | Role in IDP POC | Local README |
|--------|-----------------|--------------|
| `gke-cluster-autopilot` | Default platform + tenant Autopilot flavors | [README](../fabric/modules/gke-cluster-autopilot/README.md) |
| `gke-cluster-standard` | Standard tenant / special platform needs | [README](../fabric/modules/gke-cluster-standard/README.md) |
| `gke-nodepool` | Required companion for Standard (pools are not “free” with the cluster module alone in fabric’s model) | [README](../fabric/modules/gke-nodepool/README.md) |
| `gke-hub` | Fleet membership and fleet features for multi-cluster IDP | [README](../fabric/modules/gke-hub/README.md) |

Upstream: [cloud-foundation-fabric](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric).

**FAST vs modules:** full [Fabric FAST](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/fast/README.md) bootstraps org folders, networking factories, security, etc. Current master no longer ships a dedicated GKE stage; GKE is composed with these modules (and your own stage/wrappers). This POC stays on **modules only** until a landing zone is in scope.

---

## 5. External documentation index

- [GKE Autopilot overview](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- [Autopilot resource requests](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-resource-requests)
- [Choose cluster mode (Autopilot vs Standard)](https://cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode)
- [VPC-native clusters / alias IPs](https://cloud.google.com/kubernetes-engine/docs/concepts/alias-ips)
- [Private clusters](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)
- [Fleet management concepts](https://cloud.google.com/kubernetes-engine/fleet-management/docs/fleet-concepts)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
- [Hardening GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster)
- [Config Sync overview](https://cloud.google.com/kubernetes-engine/enterprise/config-sync/docs/overview)
- [Fabric FAST README](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/fast/README.md)

---

## 6. Suggested POC roadmap (later implementation)

Checklist only—do not treat as done:

1. Introduce a `flavor` (or equivalent) input and thin wrappers over fabric modules; keep a single GCP project for the demo.
2. Parameterize network per owner/flavor (unique subnet names + non-overlapping CIDRs).
3. Optionally register clusters with `gke-hub` for a multi-cluster story.
4. Run one **platform** and one **tenant** cluster side by side to validate the catalog.
5. If the POC graduates: Shared VPC, private clusters, remote state, and alignment with org FAST networking/security stages.

---

## 7. Open questions (fill in)

Use this section as a working checklist with stakeholders.

| Question | Answer / notes |
|----------|----------------|
| Shared VPC (host project) or project-local VPC for the POC? | |
| Fleet host project id? | |
| Tenancy model: namespace-per-team, cluster-per-team, or hybrid? | |
| Is GPU (`tenant-standard-gpu`) in scope for v1 of the POC? | |
| Private-only API endpoint required (compliance)? | |
| Which IDP product (Backstage, Port, custom, other)? | |
| Who owns Terraform state for tenant clusters (platform team vs pipeline per request)? | |
| Prod-like release channel (`REGULAR` vs `STABLE`) for platform vs tenants? | |
| Config Sync / policy required from day one? | |

---

## Related repo paths

- Current Autopilot wiring: [`gke.tf`](../gke.tf)
- Demo network: [`network.tf`](../network.tf)
- Fabric pin: [`fabric/FABRIC_VERSION`](../fabric/FABRIC_VERSION)
- Next PoC (locked scope + client demo): [IDP-GKE-POC-FLEETS-TENANTS.md](IDP-GKE-POC-FLEETS-TENANTS.md)

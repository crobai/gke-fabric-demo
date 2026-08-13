# Tenant apps — developer plane (Phase D)

Application developers deploy workloads **only** into namespaces already shaped
by the portal power-user (`../tenant-guardrails/`).

Coming in Phase D:

- `make tenant-deploy TENANT=t1-front REPLICAS=2 …`
- Deployment + ClusterIP Service + periodic probes
- Runs as the tenant identity (RBAC / quota enforced)

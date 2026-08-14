# Tenant apps — developer plane

Deploy one probe app into an existing tenant namespace (from `tenant-guardrails/`).

```bash
make tenant-deploy TENANT=t1-front REPLICAS=2
make tenant-deploy-all
make demo-logs TENANT=t1-front
make demo-rbac
make demo-quota
```

Each `TENANT` uses a Terraform workspace so deploys do not clobber each other.

See [docs/DEMO-RUNBOOK.md](../docs/DEMO-RUNBOOK.md) for the full client demo.

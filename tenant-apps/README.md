# Tenant apps — developer plane

Deploy one probe app into an existing tenant namespace (from `tenant-guardrails/`).

```bash
# single tenant (portal stand-in)
make tenant-deploy TENANT=t1-front REPLICAS=2

# all three (db → back → front so DNS peers exist)
make tenant-deploy-all

# live ALLOW/DENY lines
make tenant-logs TENANT=t1-front

# RBAC — bound only to t1-front
make tenant-can-i TENANT=t1-front AS=roberto.comsa@esolutions.ro   # yes
make tenant-can-i TENANT=t2-back AS=roberto.comsa@esolutions.ro    # no

# Quota — t1-front pods=2
make tenant-deploy TENANT=t1-front REPLICAS=3                     # exceeded quota
```

Each `TENANT` uses a Terraform workspace so deploys do not clobber each other.

Workload Identity is out of scope for this phase.

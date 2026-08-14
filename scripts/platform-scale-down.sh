#!/usr/bin/env bash
# Remove platform scale demos (ok + blocked) so the autoscaler can scale the pool down.
set -euo pipefail

NS="${NS:-platform-scale}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CLUSTER="$(terraform output -raw cluster_name 2>/dev/null || true)"
REGION="$(terraform output -raw cluster_location 2>/dev/null || true)"
PROJECT="$(grep -E '^project_id' terraform.tfvars | sed -E 's/.*=\s*"([^"]+)".*/\1/' || true)"

if [[ -z "${CLUSTER}" ]]; then
  echo "No cluster outputs yet — run make platform-up first." >&2
  exit 1
fi

if ! kubectl get nodes &>/dev/null; then
  gcloud container clusters get-credentials "${CLUSTER}" --region "${REGION}" --project "${PROJECT}"
fi

kubectl delete deployment scale-burst scale-blocked -n "${NS}" --ignore-not-found
kubectl delete namespace "${NS}" --ignore-not-found --wait=false

echo "Scale load removed (ok + blocked demos). Autoscaler may take several minutes to remove idle nodes."
echo "Watch: kubectl get nodes -w"
kubectl get nodes

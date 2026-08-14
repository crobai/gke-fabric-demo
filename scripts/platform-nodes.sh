#!/usr/bin/env bash
# Show nodes + allocatable resources (platform capacity playground).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

CLUSTER="$(terraform output -raw cluster_name 2>/dev/null || true)"
REGION="$(terraform output -raw cluster_location 2>/dev/null || true)"
PROJECT="$(grep -E '^project_id' terraform.tfvars | sed -E 's/.*=\s*"([^"]+)".*/\1/' || true)"

if [[ -z "${CLUSTER}" || -z "${REGION}" ]]; then
  echo "No cluster outputs yet — run make platform-up first." >&2
  exit 1
fi

if ! kubectl get nodes &>/dev/null; then
  echo "Getting credentials for ${CLUSTER}..."
  gcloud container clusters get-credentials "${CLUSTER}" --region "${REGION}" --project "${PROJECT}"
fi

echo "=== Nodes ==="
kubectl get nodes -o wide
echo
echo "=== Allocatable (capacity playground) ==="
kubectl get nodes -o custom-columns=\
NAME:.metadata.name,\
CPU:.status.allocatable.cpu,\
MEMORY:.status.allocatable.memory,\
PODS:.status.allocatable.pods,\
INSTANCE:.metadata.labels.'node\.kubernetes\.io/instance-type'
echo
echo "=== Pool / density knobs (from Terraform) ==="
terraform output node_pool_machine_type
terraform output max_pods_per_node
terraform output node_pool_autoscaling

#!/usr/bin/env bash
# Platform capacity demos — Cluster Autoscaler behavior.
#
# MODE=ok      (default) — pods that each fit a fresh node but together overflow one
#                          node → CA adds node(s), up to the pool max.
# MODE=blocked — one pod bigger than a node's allocatable → CA correctly refuses
#                ("NotTriggerScaleUp: Insufficient cpu" / failing scheduling predicate).
set -euo pipefail

MODE="${MODE:-ok}"
NS="${NS:-platform-scale}"
IMAGE="${IMAGE:-registry.k8s.io/pause:3.10}"
MEM_REQUEST="${MEM_REQUEST:-128Mi}"

case "${MODE}" in
  ok|scale|success)
    MODE=ok
    NAME="${NAME:-scale-burst}"
    # 2× ~900m packs a busy e2-standard-2 and forces a 2nd node once system pods are counted.
    REPLICAS="${REPLICAS:-2}"
    CPU_REQUEST="${CPU_REQUEST:-900m}"
    EXPECT="EXPECT: some pods pending on the 1st node → Cluster Autoscaler adds node(s), up to pool max."
    ;;
  blocked|fail|predicate)
    MODE=blocked
    NAME="${NAME:-scale-blocked}"
    REPLICAS="${REPLICAS:-1}"
    # Above e2-standard-2 allocatable (~1900m) so a new identical node still cannot place it.
    CPU_REQUEST="${CPU_REQUEST:-2500m}"
    EXPECT="EXPECT: CA does NOT scale up — request exceeds a single node's allocatable (~1.9 CPU on e2-standard-2)."
    ;;
  *)
    echo "MODE must be ok or blocked (got: ${MODE})" >&2
    exit 1
    ;;
esac

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

ALLOC_CPU="$(kubectl get nodes -o jsonpath='{.items[0].status.allocatable.cpu}' 2>/dev/null || true)"

echo "=== Platform autoscaling demo: MODE=${MODE} ==="
echo "Nodes before:"
kubectl get nodes
echo "Sample allocatable CPU: ${ALLOC_CPU:-unknown}"
echo "Deploy: ${REPLICAS}x cpu=${CPU_REQUEST} mem=${MEM_REQUEST} → ${NS}/${NAME}"
echo "${EXPECT}"
echo

kubectl create namespace "${NS}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${NAME}
  namespace: ${NS}
  labels:
    app: ${NAME}
    idp-plane: platform
    demo: scale-${MODE}
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${NAME}
  template:
    metadata:
      labels:
        app: ${NAME}
    spec:
      containers:
        - name: pause
          image: ${IMAGE}
          resources:
            requests:
              cpu: "${CPU_REQUEST}"
              memory: "${MEM_REQUEST}"
EOF

echo
echo "Watch: kubectl get pods -n ${NS} -o wide -w"
echo "Watch: kubectl get nodes -w"
echo "Cleanup: make platform-scale-down"
echo
kubectl get pods -n "${NS}" -o wide
kubectl get nodes

#!/usr/bin/env bash
# E3 — scale t1-front past pods=2 quota (expect exceeded), then restore.
set -euo pipefail

TENANT="${TENANT:-t1-front}"
APP="${APP_NAME:-front}"
TARGET="${TARGET_REPLICAS:-3}"
RESTORE="${RESTORE_REPLICAS:-2}"

echo "== quota demo  ns=${TENANT}  deploy/${APP}  scale ${RESTORE} → ${TARGET} =="
echo
echo "-- resourcequota before --"
kubectl -n "${TENANT}" get resourcequota tenant-quota
echo
echo "-- current replicas --"
kubectl -n "${TENANT}" get deploy "${APP}" -o wide
echo
echo "-- scale to ${TARGET} (expect: exceeded quota / pending pods) --"
kubectl -n "${TENANT}" scale "deploy/${APP}" --replicas="${TARGET}"
sleep 3
echo
echo "-- deploy / pods after scale --"
kubectl -n "${TENANT}" get deploy "${APP}"
kubectl -n "${TENANT}" get pods -l "app=${APP}" -o wide
echo
echo "-- recent events (quota) --"
kubectl -n "${TENANT}" get events --field-selector reason=FailedCreate --sort-by=.lastTimestamp 2>/dev/null \
  | tail -n 8 || kubectl -n "${TENANT}" get events --sort-by=.lastTimestamp | tail -n 12
echo
echo "-- restore replicas=${RESTORE} --"
kubectl -n "${TENANT}" scale "deploy/${APP}" --replicas="${RESTORE}"
sleep 2
kubectl -n "${TENANT}" get deploy "${APP}"
kubectl -n "${TENANT}" get resourcequota tenant-quota
echo
echo "OK: quota demo finished (restored to ${RESTORE})"

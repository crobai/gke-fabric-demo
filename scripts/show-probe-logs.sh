#!/usr/bin/env bash
# E1 — show recent probe ALLOW/DENY lines (or follow with FOLLOW=1).
set -euo pipefail

TENANT="${TENANT:-t1-front}"
FOLLOW="${FOLLOW:-0}"

case "${TENANT}" in
  t1-front) APP="${APP_NAME:-front}" ;;
  t2-back)  APP="${APP_NAME:-back}" ;;
  t3-db)    APP="${APP_NAME:-db}" ;;
  *) echo "TENANT must be t1-front, t2-back, or t3-db"; exit 1 ;;
esac

echo "== probe logs  ns=${TENANT}  deploy/${APP} =="

if [[ "${FOLLOW}" == "1" ]]; then
  kubectl logs -n "${TENANT}" "deploy/${APP}" -f --prefix=true \
    | grep --line-buffered -E 'ALLOW|DENY|FAIL|listening|UNEXPECTED'
else
  kubectl logs -n "${TENANT}" "deploy/${APP}" --tail="${TAIL:-40}" --prefix=true \
    | grep -E 'ALLOW|DENY|FAIL|listening|UNEXPECTED' || true
fi

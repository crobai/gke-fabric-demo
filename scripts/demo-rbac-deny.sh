#!/usr/bin/env bash
# E2 — t1 identity may edit t1-front, Forbidden on t2-back (RBAC).
set -euo pipefail

AS="${AS:-roberto.comsa@esolutions.ro}"
HOME_NS="${HOME_NS:-t1-front}"
OTHER_NS="${OTHER_NS:-t2-back}"

echo "== RBAC demo  as=${AS} =="
echo
echo "-- can-i create deployments in ${HOME_NS} (expect: yes) --"
kubectl auth can-i create deployments -n "${HOME_NS}" --as="${AS}"
echo
echo "-- can-i create deployments in ${OTHER_NS} (expect: no) --"
kubectl auth can-i create deployments -n "${OTHER_NS}" --as="${AS}"
echo
echo "-- server-side dry-run create in ${OTHER_NS} as ${AS} (expect: Forbidden) --"
set +e
kubectl create deployment rbac-deny-probe \
  --image=nginx:stable \
  -n "${OTHER_NS}" \
  --as="${AS}" \
  --dry-run=server \
  -o name 2>&1
rc=$?
set -e
echo
if [[ "${rc}" -ne 0 ]]; then
  echo "OK: cross-namespace deploy denied (exit ${rc})"
else
  echo "UNEXPECTED: create was allowed"
  exit 1
fi

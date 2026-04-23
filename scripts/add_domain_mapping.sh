#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:?namespace required}"
RELEASE="${2:?helm release required}"
NEW_DOMAIN="${3:?new domain required}"
TLS_SECRET="${4:-${NAMESPACE}-tls}"

helm upgrade "${RELEASE}" ./helm/tenant-site \
  -n "${NAMESPACE}" \
  -f "tenants/${NAMESPACE}-values.yaml" \
  --set ingress.host="${NEW_DOMAIN}" \
  --set ingress.tls.secretName="${TLS_SECRET}"

echo "Domain mapping updated for ${NAMESPACE}: ${NEW_DOMAIN}"

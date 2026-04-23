#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${1:?namespace required}"
RELEASE="${2:?release required}"

LAST_STABLE_REVISION="$(helm history "${RELEASE}" -n "${NAMESPACE}" -o json | jq '.[-2].revision')"

if [[ -z "${LAST_STABLE_REVISION}" || "${LAST_STABLE_REVISION}" == "null" ]]; then
  echo "No previous revision found for ${RELEASE} in ${NAMESPACE}"
  exit 1
fi

helm rollback "${RELEASE}" "${LAST_STABLE_REVISION}" -n "${NAMESPACE}"
echo "Rolled back ${RELEASE} in ${NAMESPACE} to revision ${LAST_STABLE_REVISION}"

#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:?target URL required}"
REQUESTS="${2:-20000}"
CONCURRENCY="${3:-100}"

# Uses hey image to generate load from inside cluster network.
kubectl run load-generator --rm -i --tty --restart=Never \
  --image=rakyll/hey \
  -- /hey -z 120s -c "${CONCURRENCY}" -q 10 "${TARGET_URL}" -n "${REQUESTS}"

#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f k8s/cluster/namespaces.yaml

for tenant in user1 user2 user3; do
  helm upgrade --install "${tenant}-site" ./helm/tenant-site \
    -n "${tenant}" \
    -f "tenants/${tenant}-values.yaml"
done

kubectl get all -n user1
kubectl get all -n user2
kubectl get all -n user3

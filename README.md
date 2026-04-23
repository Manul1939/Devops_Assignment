# Multi-Tenant DevOps Assignment

This repository provides a complete starter implementation for your assignment:

- 3 isolated tenant websites (`user1`, `user2`, `user3`) on Kubernetes
- Dynamic custom domain mapping using Ingress + TLS
- CI/CD pipeline with build, deploy, rollback, and Kafka event publishing
- HPA, quotas, PDB, and network policies for reliability and resource governance
- Kafka single-node runtime for deployment events
- Prometheus/Grafana observability and load-test flow

## Repository Structure

- `apps/node-app` - Sample Node.js web app
- `apps/flask-app` - Sample Flask web app
- `helm/tenant-site` - Reusable Helm chart for each tenant website
- `tenants/*.yaml` - Per-user overrides (domain, image, ports)
- `k8s/cluster` - Shared cluster setup (namespaces, cert-manager issuer)
- `.github/workflows/cicd.yml` - CI/CD automation pipeline
- `events` - Kafka producer/consumer scripts
- `observability` - Prometheus values + load test helper
- `scripts` - Deploy/rollback/domain update scripts

## Prerequisites (From Scratch)

Install these tools:

1. Docker Desktop
2. Kubernetes cluster (Minikube, Kind, EKS, AKS, GKE, etc.)
3. `kubectl`
4. `helm`
5. Python 3.10+
6. `jq` (required by rollback scripts/pipeline)
7. GitHub repo with Actions enabled (for CI/CD section)

## Step 1: Prepare Kubernetes Add-ons

Install ingress-nginx and cert-manager:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace

helm upgrade --install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true
```

Apply namespaces and issuer:

```bash
kubectl apply -f k8s/cluster/namespaces.yaml
kubectl apply -f k8s/cluster/cluster-issuer.yaml
```

## Step 2: Build and Push Sample Images

Replace `ghcr.io/your-org` with your registry.

```bash
# Node app
docker build -t ghcr.io/your-org/tenant-node-app:main ./apps/node-app
docker push ghcr.io/your-org/tenant-node-app:main

# Flask app
docker build -t ghcr.io/your-org/tenant-flask-app:main ./apps/flask-app
docker push ghcr.io/your-org/tenant-flask-app:main
```

## Step 3: Deploy 3 Tenants (Isolated Namespaces)

```bash
bash scripts/deploy_all_tenants.sh
```

This deploys:

- `user1-site` in namespace `user1`
- `user2-site` in namespace `user2`
- `user3-site` in namespace `user3`

Each tenant gets:

- Deployment + Service
- Ingress with TLS annotations
- Liveness/Readiness probes
- Resource requests/limits
- HPA (CPU + memory)
- PodDisruptionBudget
- NetworkPolicy
- ResourceQuota + LimitRange

## Step 4: Verify Multi-Tenant Access

Collect assignment proof:

```bash
kubectl get all -n user1
kubectl get all -n user2
kubectl get all -n user3
```

Get ingress IP:

```bash
kubectl get ingress -A
```

Then test with `curl`:

```bash
curl -H "Host: user1.example.com" http://<INGRESS_IP>/
curl -H "Host: user2.example.com" http://<INGRESS_IP>/
curl -H "Host: user3.example.com" http://<INGRESS_IP>/
```

For HTTPS verification (after certs are ready):

```bash
curl https://user1.example.com/
curl https://user2.example.com/
curl https://user3.example.com/
```

## Dynamic Domain Mapping Approach (Short Explanation)

Dynamic domain mapping is handled by Ingress host rules. To map a new domain, you update only tenant values/Ingress and run `helm upgrade` for that tenant release. The cluster itself is not redeployed; only the tenant ingress object is reconciled. TLS is automatic through cert-manager annotations and per-domain certificate secrets.

Example:

```bash
bash scripts/add_domain_mapping.sh user1 user1-site blog.user1.example.com user1-blog-tls
```

## Step 5: CI/CD Pipeline (Build, Deploy, Rollback, Kafka Event)

Pipeline file: `.github/workflows/cicd.yml`

What it does:

1. Builds and pushes images for each tenant (matrix strategy)
2. Deploys via Helm into each namespace
3. On deployment failure, attempts rollback to previous revision
4. On success, publishes a Kafka deployment event

Set GitHub repository secrets:

- `KUBE_CONFIG_DATA` (base64 kubeconfig)
- `KAFKA_BOOTSTRAP` (example: `your-kafka-host:9092`)

Optional adjustment:

- Change `IMAGE_NAMESPACE` in workflow to your registry namespace.

## Step 6: Kafka Event-Driven Flow

Run Kafka locally:

```bash
docker compose -f docker-compose.kafka.yml up -d
```

Create Python env and deps:

```bash
python -m venv .venv
# Windows PowerShell:
.venv\Scripts\Activate.ps1
# Linux/macOS:
# source .venv/bin/activate
pip install -r events/requirements.txt
```

Start consumer:

```bash
python events/consume_events.py
```

Publish test event:

```bash
set TENANT=user1
set NAMESPACE=user1
set DOMAIN=user1.example.com
set IMAGE=ghcr.io/your-org/tenant-node-app:main
set STATUS=deployed
set KAFKA_BOOTSTRAP=localhost:9092
python events/publish_event.py
```

For PowerShell:

```powershell
$env:TENANT="user1"
$env:NAMESPACE="user1"
$env:DOMAIN="user1.example.com"
$env:IMAGE="ghcr.io/your-org/tenant-node-app:main"
$env:STATUS="deployed"
$env:KAFKA_BOOTSTRAP="localhost:9092"
python events/publish_event.py
```

Capture screenshot showing consumer output.

## Step 7: Scaling, Resource Optimization, and Uptime

HPA is already included in Helm chart (`templates/hpa.yaml`) and uses CPU + memory metrics.

Enable metrics server if missing:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Generate load:

```bash
bash observability/load-test.sh http://user1-site.user1.svc.cluster.local/
```

Observe scaling:

```bash
kubectl get hpa -n user1 -w
kubectl get pods -n user1 -w
```

Resource controls:

- `ResourceQuota` caps namespace resource consumption
- `LimitRange` enforces default per-container requests/limits
- `PodDisruptionBudget` keeps at least one pod available during maintenance

## Step 8: Observability with Prometheus + Grafana

Install stack:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f observability/prometheus-values.yaml
```

Port-forward Grafana:

```bash
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
```

Open `http://localhost:3000` (default user `admin`, password `admin`) and capture:

- Cluster CPU/memory
- Namespace `user1/user2/user3` workloads
- Pod restart/error trends

## Assignment Deliverables Checklist

1. **Git repo content**
   - Dockerfiles: `apps/node-app/Dockerfile`, `apps/flask-app/Dockerfile`
   - Helm/K8s manifests: `helm/tenant-site`, `k8s/cluster`
   - CI/CD config: `.github/workflows/cicd.yml`
2. **README**
   - This file documents deployment, scaling, rollback, and events
3. **Proof artifacts to capture**
   - `kubectl get all -n user1/user2/user3`
   - Browser/curl proof per domain
   - CI success + rollback logs/screenshots
   - Kafka publish/consume screenshot
   - HPA scaling metrics/logs
   - Grafana dashboards

## Notes for Demo Stability

- Start with `letsencrypt-staging` issuer to avoid production rate limits.
- For local clusters without public DNS, use host-header curl tests and `/etc/hosts` mapping.
- If rollback has no prior revision, first successful deployment must exist before a rollback target exists.

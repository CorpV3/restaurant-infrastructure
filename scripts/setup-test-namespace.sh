#!/bin/bash
# Setup Test Namespace with Helm
# Deploys restaurant-system to restaurant-test namespace for testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELM_DIR="$SCRIPT_DIR/../helm/restaurant-system"
NAMESPACE="restaurant-test"
RELEASE_NAME="restaurant-test"

echo "=== Setting up $NAMESPACE namespace with Helm ==="

# 1. Create namespace if not exists
echo "1. Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Label namespace for Istio injection (if using Istio)
kubectl label namespace $NAMESPACE istio-injection=enabled --overwrite 2>/dev/null || true

# 2. Deploy with Helm
echo "2. Deploying with Helm..."
helm upgrade --install $RELEASE_NAME $HELM_DIR \
  --namespace $NAMESPACE \
  --values $HELM_DIR/values-test.yaml \
  --wait \
  --timeout 10m

# 3. Wait for all pods to be ready
echo "3. Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n $NAMESPACE --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=rabbitmq -n $NAMESPACE --timeout=300s || true
kubectl wait --for=condition=ready pod -l app=redis -n $NAMESPACE --timeout=300s || true

# 4. Show deployment status
echo ""
echo "=== Deployment Status ==="
kubectl get pods -n $NAMESPACE

echo ""
echo "=== Setup Complete ==="
echo "Namespace: $NAMESPACE"
echo "Helm Release: $RELEASE_NAME"
echo ""
echo "Commands:"
echo "  Check pods:      kubectl get pods -n $NAMESPACE"
echo "  Check services:  kubectl get svc -n $NAMESPACE"
echo "  View logs:       kubectl logs -f deploy/<service-name> -n $NAMESPACE"
echo ""
echo "Port-forward to test locally:"
echo "  Frontend:    kubectl port-forward svc/frontend -n $NAMESPACE 3000:80"
echo "  API Gateway: kubectl port-forward svc/api-gateway-service -n $NAMESPACE 8000:8000"

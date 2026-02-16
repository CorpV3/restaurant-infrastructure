#!/bin/bash
# Setup Test Namespace Script
# Creates the restaurant-test namespace with all required resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../kubernetes"

echo "=== Setting up restaurant-test namespace ==="

# 1. Create namespace
echo "1. Creating namespace..."
kubectl apply -f $K8S_DIR/namespace.yaml

# 2. Create secrets (copy from production or create new)
echo "2. Creating secrets..."
kubectl apply -f $K8S_DIR/secrets.yaml
kubectl apply -f $K8S_DIR/integration-secrets.yaml

# 3. Create configmap
echo "3. Creating configmap..."
kubectl apply -f $K8S_DIR/configmap.yaml

# 4. Deploy infrastructure (PostgreSQL, RabbitMQ, Redis)
echo "4. Deploying infrastructure..."
kubectl apply -f $K8S_DIR/postgres-statefulset.yaml
kubectl apply -f $K8S_DIR/rabbitmq-statefulset.yaml
kubectl apply -f $K8S_DIR/redis-statefulset.yaml

# 5. Wait for infrastructure to be ready
echo "5. Waiting for infrastructure..."
kubectl wait --for=condition=ready pod/postgres-0 -n restaurant-test --timeout=300s
kubectl wait --for=condition=ready pod/rabbitmq-0 -n restaurant-test --timeout=300s
kubectl wait --for=condition=ready pod/redis-0 -n restaurant-test --timeout=300s

# 6. Replicate database
echo "6. Replicating database from production..."
bash $SCRIPT_DIR/replicate-database.sh

# 7. Deploy services
echo "7. Deploying services..."
kubectl apply -f $K8S_DIR/api-gateway-deployment.yaml
kubectl apply -f $K8S_DIR/auth-service-deployment.yaml
kubectl apply -f $K8S_DIR/restaurant-service-deployment.yaml
kubectl apply -f $K8S_DIR/order-service-deployment.yaml
kubectl apply -f $K8S_DIR/customer-service-deployment.yaml
kubectl apply -f $K8S_DIR/integration-service-deployment.yaml
kubectl apply -f $K8S_DIR/frontend-deployment.yaml

# 8. Deploy ingress (if needed)
echo "8. Setting up networking..."
kubectl apply -f $K8S_DIR/ingress.yaml

echo ""
echo "=== Setup complete ==="
echo "Namespace: restaurant-test"
echo ""
echo "Check pod status:"
echo "  kubectl get pods -n restaurant-test"
echo ""
echo "Port-forward to test locally:"
echo "  kubectl port-forward svc/frontend -n restaurant-test 3000:80"
echo "  kubectl port-forward svc/api-gateway-service -n restaurant-test 8000:8000"

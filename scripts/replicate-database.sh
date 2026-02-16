#!/bin/bash
# Database Replication Script
# This script copies data from production (restaurant-system) to test (restaurant-test) namespace

set -e

PROD_NAMESPACE="restaurant-system"
TEST_NAMESPACE="restaurant-test"
PROD_POD="postgres-0"
TEST_POD="postgres-0"
DATABASES=("restaurant_db" "auth_db" "order_db" "customer_db")

echo "=== Database Replication: $PROD_NAMESPACE -> $TEST_NAMESPACE ==="

# Check if test namespace exists
if ! kubectl get namespace $TEST_NAMESPACE &> /dev/null; then
    echo "Creating test namespace..."
    kubectl apply -f ../kubernetes/namespace.yaml
fi

# Wait for test PostgreSQL to be ready
echo "Waiting for test PostgreSQL to be ready..."
kubectl wait --for=condition=ready pod/$TEST_POD -n $TEST_NAMESPACE --timeout=300s

# Get production database credentials
PROD_USER=$(kubectl get secret restaurant-secrets -n $PROD_NAMESPACE -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)
PROD_PASS=$(kubectl get secret restaurant-secrets -n $PROD_NAMESPACE -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)

echo "Replicating databases..."

for DB in "${DATABASES[@]}"; do
    echo "  Replicating $DB..."

    # Dump from production
    kubectl exec -n $PROD_NAMESPACE $PROD_POD -c postgres -- \
        pg_dump -U $PROD_USER -d $DB --no-owner --no-acl > /tmp/${DB}_dump.sql

    # Check if database exists in test, create if not
    kubectl exec -n $TEST_NAMESPACE $TEST_POD -c postgres -- \
        psql -U $PROD_USER -c "CREATE DATABASE $DB;" 2>/dev/null || true

    # Restore to test
    kubectl exec -n $TEST_NAMESPACE $TEST_POD -c postgres -- \
        psql -U $PROD_USER -d $DB < /tmp/${DB}_dump.sql

    # Cleanup
    rm -f /tmp/${DB}_dump.sql

    echo "  ✓ $DB replicated"
done

echo ""
echo "=== Database replication complete ==="
echo "Test namespace: $TEST_NAMESPACE"
echo "Databases replicated: ${DATABASES[*]}"

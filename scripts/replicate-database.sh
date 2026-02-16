#!/bin/bash
# Database Replication Script
# Copies data from production (restaurant-system) to test (restaurant-test) namespace

set -e

PROD_NAMESPACE="restaurant-system"
TEST_NAMESPACE="restaurant-test"
PROD_POD="postgres-0"
TEST_POD="postgres-0"
DATABASES=("restaurant_db" "auth_db" "order_db" "customer_db")

echo "=== Database Replication: $PROD_NAMESPACE -> $TEST_NAMESPACE ==="

# Check if test namespace exists
if ! kubectl get namespace $TEST_NAMESPACE &> /dev/null; then
    echo "Error: Test namespace $TEST_NAMESPACE does not exist."
    echo "Run setup-test-namespace.sh first."
    exit 1
fi

# Check if test PostgreSQL is ready
echo "Checking test PostgreSQL..."
kubectl wait --for=condition=ready pod/$TEST_POD -n $TEST_NAMESPACE --timeout=60s

# Get database credentials from production
PROD_USER=$(kubectl get secret restaurant-secrets -n $PROD_NAMESPACE -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)
PROD_PASS=$(kubectl get secret restaurant-secrets -n $PROD_NAMESPACE -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)

echo "Database user: $PROD_USER"
echo ""
echo "Replicating databases..."

for DB in "${DATABASES[@]}"; do
    echo "  [$DB] Dumping from production..."

    # Dump from production (schema + data)
    kubectl exec -n $PROD_NAMESPACE $PROD_POD -c postgres -- \
        pg_dump -U $PROD_USER -d $DB --no-owner --no-acl --clean --if-exists 2>/dev/null > /tmp/${DB}_dump.sql

    if [ ! -s /tmp/${DB}_dump.sql ]; then
        echo "  [$DB] Warning: Empty dump, skipping..."
        continue
    fi

    echo "  [$DB] Creating database in test if not exists..."
    kubectl exec -n $TEST_NAMESPACE $TEST_POD -c postgres -- \
        psql -U $PROD_USER -c "CREATE DATABASE $DB;" 2>/dev/null || true

    echo "  [$DB] Restoring to test..."
    kubectl exec -i -n $TEST_NAMESPACE $TEST_POD -c postgres -- \
        psql -U $PROD_USER -d $DB < /tmp/${DB}_dump.sql 2>/dev/null

    # Cleanup
    rm -f /tmp/${DB}_dump.sql

    echo "  [$DB] ✓ Done"
done

echo ""
echo "=== Database replication complete ==="
echo ""
echo "Verify with:"
echo "  kubectl exec -n $TEST_NAMESPACE $TEST_POD -c postgres -- psql -U $PROD_USER -c '\\l'"

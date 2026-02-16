#!/bin/bash

# Port-forward script for Restaurant Management System - TEST Environment
# Quick access to all services in restaurant-test namespace

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# PID file
PID_FILE="/tmp/restaurant-test-portforward.pid"

# Cleanup function
cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping all port-forwards...${NC}"
    if [ -f "$PID_FILE" ]; then
        while IFS= read -r pid; do
            if kill -0 "$pid" 2>/dev/null; then
                kill "$pid" 2>/dev/null || true
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    echo -e "${GREEN}✅ All port-forwards stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

echo -e "${MAGENTA}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║  Restaurant Management - TEST Environment        ║${NC}"
echo -e "${MAGENTA}║  Namespace: restaurant-test                      ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not installed${NC}"
    exit 1
fi

# Check cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

# Check namespace
if ! kubectl get namespace restaurant-test &> /dev/null; then
    echo -e "${RED}❌ restaurant-test namespace not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting port-forwards for TEST environment...${NC}"
echo -e "${YELLOW}(Using ports 9xxx to avoid conflicts with production)${NC}"
echo ""

rm -f "$PID_FILE"

# 1. Frontend (port 9080)
echo -e "${CYAN}1. Starting Frontend...${NC}"
kubectl port-forward -n restaurant-test svc/frontend 9080:80 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ Frontend on http://localhost:9080${NC}"
echo ""

# 2. API Gateway (port 9000)
echo -e "${CYAN}2. Starting API Gateway...${NC}"
kubectl port-forward -n restaurant-test svc/api-gateway 9000:8000 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ API Gateway on http://localhost:9000${NC}"
echo -e "${GREEN}   ✅ API Docs on http://localhost:9000/docs${NC}"
echo ""

# 3. Auth Service (port 9001)
echo -e "${CYAN}3. Starting Auth Service...${NC}"
kubectl port-forward -n restaurant-test svc/auth-service 9001:8001 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ Auth Service on http://localhost:9001${NC}"
echo ""

# 4. Restaurant Service (port 9003)
echo -e "${CYAN}4. Starting Restaurant Service...${NC}"
kubectl port-forward -n restaurant-test svc/restaurant-service 9003:8003 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ Restaurant Service on http://localhost:9003${NC}"
echo ""

# 5. Order Service (port 9004)
echo -e "${CYAN}5. Starting Order Service...${NC}"
kubectl port-forward -n restaurant-test svc/order-service 9004:8004 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ Order Service on http://localhost:9004${NC}"
echo ""

# 6. Customer Service (port 9007)
if kubectl get svc customer-service -n restaurant-test &> /dev/null; then
    echo -e "${CYAN}6. Starting Customer Service...${NC}"
    kubectl port-forward -n restaurant-test svc/customer-service 9007:8007 > /dev/null 2>&1 &
    echo $! >> "$PID_FILE"
    sleep 2
    echo -e "${GREEN}   ✅ Customer Service on http://localhost:9007${NC}"
    echo ""
fi

# 7. Integration Service (port 9015)
if kubectl get svc integration-service -n restaurant-test &> /dev/null; then
    echo -e "${CYAN}7. Starting Integration Service...${NC}"
    kubectl port-forward -n restaurant-test svc/integration-service 9015:8015 > /dev/null 2>&1 &
    echo $! >> "$PID_FILE"
    sleep 2
    echo -e "${GREEN}   ✅ Integration Service on http://localhost:9015${NC}"
    echo ""
fi

# 8. PostgreSQL (port 9432)
echo -e "${CYAN}8. Starting PostgreSQL...${NC}"
kubectl port-forward -n restaurant-test svc/postgres-service 9432:5432 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ PostgreSQL on localhost:9432${NC}"
echo ""

# 9. Redis (port 9379)
echo -e "${CYAN}9. Starting Redis...${NC}"
kubectl port-forward -n restaurant-test svc/redis-service 9379:6379 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ Redis on localhost:9379${NC}"
echo ""

# 10. RabbitMQ (ports 9672, 19672)
echo -e "${CYAN}10. Starting RabbitMQ...${NC}"
kubectl port-forward -n restaurant-test svc/rabbitmq-service 19672:15672 9672:5672 > /dev/null 2>&1 &
echo $! >> "$PID_FILE"
sleep 2
echo -e "${GREEN}   ✅ RabbitMQ Management on http://localhost:19672${NC}"
echo -e "${GREEN}   ✅ RabbitMQ AMQP on localhost:9672${NC}"
echo ""

echo -e "${MAGENTA}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║    TEST Environment Port-Forwards Running!        ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 TEST Environment Service URLs:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Frontend:           http://localhost:9080"
echo -e "API Gateway:        http://localhost:9000"
echo -e "API Docs:           http://localhost:9000/docs"
echo -e "Auth Service:       http://localhost:9001"
echo -e "Restaurant Svc:     http://localhost:9003"
echo -e "Order Service:      http://localhost:9004"
echo -e "Customer Service:   http://localhost:9007"
echo -e "Integration Svc:    http://localhost:9015"
echo -e "PostgreSQL:         localhost:9432"
echo -e "Redis:              localhost:9379"
echo -e "RabbitMQ Console:   http://localhost:19672 (guest/guest)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}💡 Test Credentials (same as production):${NC}"
echo "   Master Admin:      admin / password"
echo "   Restaurant Admin:  adminres / password"
echo "   Chef:              adminchef / password"
echo ""

echo -e "${YELLOW}🔍 Useful Commands:${NC}"
echo "   Check pods:        kubectl get pods -n restaurant-test"
echo "   View logs:         kubectl logs -f <pod-name> -n restaurant-test"
echo "   Restart service:   kubectl rollout restart deployment/<name> -n restaurant-test"
echo ""

echo -e "${YELLOW}📌 Port Mapping (Test vs Production):${NC}"
echo "   Frontend:     9080 (test) vs 3000 (prod)"
echo "   API Gateway:  9000 (test) vs 8000 (prod)"
echo "   PostgreSQL:   9432 (test) vs 5432 (prod)"
echo ""

echo -e "${MAGENTA}✨ TEST environment ready! Press CTRL+C to stop all port-forwards.${NC}"
echo ""

# Keep running and monitor
while true; do
    sleep 30
    RUNNING=0
    TOTAL=0
    if [ -f "$PID_FILE" ]; then
        while IFS= read -r pid; do
            TOTAL=$((TOTAL + 1))
            if kill -0 "$pid" 2>/dev/null; then
                RUNNING=$((RUNNING + 1))
            fi
        done < "$PID_FILE"
    fi
    echo -e "${CYAN}[$(date '+%H:%M:%S')] TEST ENV Status: ${RUNNING}/${TOTAL} port-forwards running${NC}"

    if [ "$RUNNING" -lt "$TOTAL" ]; then
        echo -e "${RED}⚠️  Some port-forwards stopped. Exiting...${NC}"
        cleanup
    fi
done

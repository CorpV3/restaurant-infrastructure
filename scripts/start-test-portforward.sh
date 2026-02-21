#!/bin/bash

# Port-forward script for Restaurant Management System - TEST Environment
# Quick access to all services in restaurant-test namespace

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
            kill "$pid" 2>/dev/null || true
        done < "$PID_FILE"
        rm -f "$PID_FILE"
    fi
    echo -e "${GREEN}✅ All port-forwards stopped${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM

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

rm -f "$PID_FILE"

# Service definitions: "name localPort:remotePort label"
declare -A SERVICES
SERVICES=(
    ["frontend"]="9080:80"
    ["api-gateway"]="9000:8000"
    ["auth-service"]="9001:8001"
    ["restaurant-service"]="9003:8003"
    ["order-service"]="9004:8004"
    ["customer-service"]="9007:8007"
    ["payment-service"]="9010:8010"
    ["receipt-service"]="9011:8011"
    ["integration-service"]="9015:8015"
    ["postgres-service"]="9432:5432"
    ["redis-service"]="9379:6379"
)
RABBITMQ_PF="19672:15672 9672:5672"

start_portforward() {
    local svc=$1
    local ports=$2
    if kubectl get svc "$svc" -n restaurant-test &> /dev/null; then
        kubectl port-forward -n restaurant-test "svc/$svc" $ports > /dev/null 2>&1 &
        local pid=$!
        echo "$pid" >> "$PID_FILE"
        sleep 1
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}   ✅ $svc ($ports)${NC}"
            return 0
        else
            echo -e "${RED}   ❌ $svc failed to start${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}   ⚠️  $svc not found, skipping${NC}"
        return 1
    fi
}

restart_portforward() {
    local svc=$1
    local ports=$2
    local old_pid=$3
    # Remove old pid
    grep -v "^${old_pid}$" "$PID_FILE" > "${PID_FILE}.tmp" && mv "${PID_FILE}.tmp" "$PID_FILE"
    kubectl port-forward -n restaurant-test "svc/$svc" $ports > /dev/null 2>&1 &
    local new_pid=$!
    echo "$new_pid" >> "$PID_FILE"
    echo "$new_pid"
}

echo -e "${YELLOW}Starting port-forwards for TEST environment...${NC}"
echo -e "${YELLOW}(Using ports 9xxx to avoid conflicts with production)${NC}"
echo ""

echo -e "${CYAN}Core Services:${NC}"
start_portforward "frontend" "9080:80"
start_portforward "api-gateway" "9000:8000"
start_portforward "auth-service" "9001:8001"
start_portforward "restaurant-service" "9003:8003"
start_portforward "order-service" "9004:8004"
start_portforward "customer-service" "9007:8007"
echo ""

echo -e "${CYAN}POS Services:${NC}"
start_portforward "payment-service" "9010:8010"
start_portforward "receipt-service" "9011:8011"
echo ""

echo -e "${CYAN}Infrastructure:${NC}"
start_portforward "integration-service" "9015:8015"
start_portforward "postgres-service" "9432:5432"
start_portforward "redis-service" "9379:6379"

# RabbitMQ (two ports)
if kubectl get svc rabbitmq-service -n restaurant-test &> /dev/null; then
    kubectl port-forward -n restaurant-test svc/rabbitmq-service $RABBITMQ_PF > /dev/null 2>&1 &
    echo $! >> "$PID_FILE"
    sleep 1
    echo -e "${GREEN}   ✅ rabbitmq-service (19672:15672, 9672:5672)${NC}"
else
    echo -e "${YELLOW}   ⚠️  rabbitmq-service not found, skipping${NC}"
fi
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
echo -e "Payment Service:    http://localhost:9010"
echo -e "Receipt Service:    http://localhost:9011"
echo -e "Integration Svc:    http://localhost:9015"
echo -e "PostgreSQL:         localhost:9432"
echo -e "Redis:              localhost:9379"
echo -e "RabbitMQ Console:   http://localhost:19672 (guest/guest)"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}💡 Test Credentials:${NC}"
echo "   Master Admin:      admin / password"
echo "   Restaurant Admin:  adminres / password"
echo "   Chef:              adminchef / password"
echo ""

echo -e "${YELLOW}📌 Port Mapping (Test vs Production):${NC}"
echo "   Frontend:         9080 (test) vs 3000 (prod)"
echo "   API Gateway:      9000 (test) vs 8000 (prod)"
echo "   Payment Service:  9010 (test)"
echo "   Receipt Service:  9011 (test)"
echo "   PostgreSQL:       9432 (test) vs 5432 (prod)"
echo ""

echo -e "${YELLOW}🖥️  POS Desktop App - set API URL to:${NC}"
echo "   http://localhost:9000  (from this machine)"
echo "   http://$(hostname -I | awk '{print $1}'):9000  (from Windows over LAN)"
echo ""

echo -e "${MAGENTA}✨ TEST environment ready! Press CTRL+C to stop all port-forwards.${NC}"
echo -e "${YELLOW}   (Auto-restarts any dropped port-forwards every 30s)${NC}"
echo ""

# Keep running - auto-restart any dropped port-forwards
declare -A SVC_PORTS=(
    ["frontend"]="9080:80"
    ["api-gateway"]="9000:8000"
    ["auth-service"]="9001:8001"
    ["restaurant-service"]="9003:8003"
    ["order-service"]="9004:8004"
    ["customer-service"]="9007:8007"
    ["payment-service"]="9010:8010"
    ["receipt-service"]="9011:8011"
    ["integration-service"]="9015:8015"
    ["postgres-service"]="9432:5432"
    ["redis-service"]="9379:6379"
)

declare -A SVC_PIDS
# Build initial pid-to-service map from PID_FILE
pid_index=0
svc_order=("frontend" "api-gateway" "auth-service" "restaurant-service" "order-service" "customer-service" "payment-service" "receipt-service" "integration-service" "postgres-service" "redis-service" "rabbitmq-service")
while IFS= read -r pid; do
    svc="${svc_order[$pid_index]}"
    SVC_PIDS[$svc]=$pid
    pid_index=$((pid_index + 1))
done < "$PID_FILE"

while true; do
    sleep 30
    RUNNING=0
    TOTAL=0
    RESTARTED=0

    for svc in "${!SVC_PORTS[@]}"; do
        if kubectl get svc "$svc" -n restaurant-test &> /dev/null; then
            TOTAL=$((TOTAL + 1))
            pid=${SVC_PIDS[$svc]:-0}
            if kill -0 "$pid" 2>/dev/null; then
                RUNNING=$((RUNNING + 1))
            else
                # Auto-restart
                ports="${SVC_PORTS[$svc]}"
                kubectl port-forward -n restaurant-test "svc/$svc" $ports > /dev/null 2>&1 &
                new_pid=$!
                SVC_PIDS[$svc]=$new_pid
                RUNNING=$((RUNNING + 1))
                RESTARTED=$((RESTARTED + 1))
            fi
        fi
    done

    # RabbitMQ
    if kubectl get svc rabbitmq-service -n restaurant-test &> /dev/null; then
        TOTAL=$((TOTAL + 1))
        pid=${SVC_PIDS["rabbitmq-service"]:-0}
        if kill -0 "$pid" 2>/dev/null; then
            RUNNING=$((RUNNING + 1))
        else
            kubectl port-forward -n restaurant-test svc/rabbitmq-service $RABBITMQ_PF > /dev/null 2>&1 &
            SVC_PIDS["rabbitmq-service"]=$!
            RUNNING=$((RUNNING + 1))
            RESTARTED=$((RESTARTED + 1))
        fi
    fi

    if [ "$RESTARTED" -gt 0 ]; then
        echo -e "${YELLOW}[$(date '+%H:%M:%S')] ♻️  Restarted $RESTARTED port-forward(s). ${RUNNING}/${TOTAL} running${NC}"
    else
        echo -e "${CYAN}[$(date '+%H:%M:%S')] TEST ENV Status: ${RUNNING}/${TOTAL} port-forwards running ✅${NC}"
    fi
done

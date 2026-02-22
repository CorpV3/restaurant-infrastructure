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

echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     Restaurant Management - TEST Environment              ║${NC}"
echo -e "${MAGENTA}║     Namespace: restaurant-test                            ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
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

RABBITMQ_PF="19672:15672 9672:5672"

# Generic port-forward helper: start_pf <namespace> <svc> <ports> <label>
start_pf() {
    local ns=$1
    local svc=$2
    local ports=$3
    local label=${4:-$svc}
    if kubectl get svc "$svc" -n "$ns" &> /dev/null; then
        kubectl port-forward -n "$ns" "svc/$svc" $ports > /dev/null 2>&1 &
        local pid=$!
        echo "$pid" >> "$PID_FILE"
        sleep 1
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}   ✅ $label ($ports)${NC}"
            return 0
        else
            echo -e "${RED}   ❌ $label failed to start${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}   ⚠️  $label not found, skipping${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Clearing any existing port-forwards on test ports...${NC}"
for port in 9080 9000 9001 9003 9004 9007 9010 9011 9015 \
            9432 9379 9672 19672 \
            9088 9300 9090 9093 9200 9686; do
    pid=$(lsof -ti :$port 2>/dev/null)
    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null || true
    fi
done
sleep 2s
echo ""

echo -e "${YELLOW}Starting port-forwards for TEST environment...${NC}"
echo -e "${YELLOW}(Using ports 9xxx to avoid conflicts with production)${NC}"
echo ""

# ── Core Application Services (restaurant-test) ──────────────────────────────
echo -e "${CYAN}Core Services:${NC}"
start_pf restaurant-test frontend            "9080:80"
start_pf restaurant-test api-gateway         "9000:8000"
start_pf restaurant-test auth-service        "9001:8001"
start_pf restaurant-test restaurant-service  "9003:8003"
start_pf restaurant-test order-service       "9004:8004"
start_pf restaurant-test customer-service    "9007:8007"
echo ""

# ── POS Services (restaurant-test) ───────────────────────────────────────────
echo -e "${CYAN}POS Services:${NC}"
start_pf restaurant-test payment-service     "9010:8010"
start_pf restaurant-test receipt-service     "9011:8011"
echo ""

# ── Infrastructure (restaurant-test) ─────────────────────────────────────────
echo -e "${CYAN}Infrastructure:${NC}"
start_pf restaurant-test integration-service "9015:8015"
start_pf restaurant-test postgres-service    "9432:5432"
start_pf restaurant-test redis-service       "9379:6379"

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

# ── Monitoring & Observability (istio-system) ─────────────────────────────────
echo -e "${CYAN}Monitoring & Observability:${NC}"
start_pf istio-system grafana                "9300:80"         "Grafana"
start_pf istio-system prometheus-server      "9090:80"         "Prometheus"
start_pf istio-system prometheus-alertmanager "9093:9093"      "AlertManager"
start_pf istio-system kiali                  "9200:20001"      "Kiali"
start_pf istio-system jaeger-query           "9686:16686"      "Jaeger"
echo ""

# ── Management ────────────────────────────────────────────────────────────────
echo -e "${CYAN}Management:${NC}"
start_pf argocd argocd-server                "9088:80"         "ArgoCD"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║       TEST Environment Port-Forwards Running!             ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 Application URLs:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Frontend:           http://localhost:9080"
echo -e "  API Gateway:        http://localhost:9000"
echo -e "  API Docs:           http://localhost:9000/docs"
echo -e "  Auth Service:       http://localhost:9001"
echo -e "  Restaurant Svc:     http://localhost:9003"
echo -e "  Order Service:      http://localhost:9004"
echo -e "  Customer Service:   http://localhost:9007"
echo -e "  Payment Service:    http://localhost:9010"
echo -e "  Receipt Service:    http://localhost:9011"
echo -e "  Integration Svc:    http://localhost:9015"
echo ""
echo -e "${CYAN}🗄️  Databases & Queues:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  PostgreSQL:         localhost:9432"
echo -e "  Redis:              localhost:9379"
echo -e "  RabbitMQ AMQP:      localhost:9672"
echo -e "  RabbitMQ Console:   http://localhost:19672"
echo ""
echo -e "${CYAN}📈 Monitoring & Observability:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Grafana:            http://localhost:9300"
echo -e "  Prometheus:         http://localhost:9090"
echo -e "  AlertManager:       http://localhost:9093"
echo -e "  Kiali:              http://localhost:9200"
echo -e "  Jaeger (Tracing):   http://localhost:9686"
echo ""
echo -e "${CYAN}⚙️  Management Tools:${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ArgoCD:             http://localhost:9088"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${YELLOW}🔑 Credentials:${NC}"
echo -e "  ┌─────────────────────────────────────────────────────────┐"
echo -e "  │  App (Master Admin)    admin         / password         │"
echo -e "  │  App (Rest. Admin)     adminres      / password         │"
echo -e "  │  App (Chef)            adminchef     / password         │"
echo -e "  ├─────────────────────────────────────────────────────────┤"
echo -e "  │  ArgoCD                admin         / myq45CaeIZQNPgkA │"
echo -e "  │  Grafana               admin         / changeme123      │"
echo -e "  │  RabbitMQ              guest         / guest            │"
echo -e "  │  Prometheus            (no auth)                        │"
echo -e "  │  Kiali                 (no auth)                        │"
echo -e "  │  Jaeger                (no auth)                        │"
echo -e "  │  Longhorn              (no auth)                        │"
echo -e "  └─────────────────────────────────────────────────────────┘"
echo ""

echo -e "${YELLOW}🖥️  POS Desktop App - set API URL to:${NC}"
echo "   http://localhost:9000            (from this machine)"
echo "   http://$(hostname -I | awk '{print $1}'):9000   (from Windows over LAN)"
echo ""

echo -e "${MAGENTA}✨ TEST environment ready! Press CTRL+C to stop all port-forwards.${NC}"
echo -e "${YELLOW}   (Auto-restarts any dropped port-forwards every 30s)${NC}"
echo ""

# ── Auto-restart loop ─────────────────────────────────────────────────────────
declare -A SVC_PIDS

# restaurant-test services
declare -A TEST_SVCS=(
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

# istio-system monitoring services
declare -A ISTIO_SVCS=(
    ["grafana"]="9300:80"
    ["prometheus-server"]="9090:80"
    ["prometheus-alertmanager"]="9093:9093"
    ["kiali"]="9200:20001"
    ["jaeger-query"]="9686:16686"
)

# Build initial PID map by reading PID_FILE in order of startup
pid_index=0
svc_order=(
    "frontend" "api-gateway" "auth-service" "restaurant-service" "order-service"
    "customer-service" "payment-service" "receipt-service" "integration-service"
    "postgres-service" "redis-service" "rabbitmq-service"
    "grafana" "prometheus-server" "prometheus-alertmanager" "kiali" "jaeger-query"
    "argocd-server"
)
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

    # restaurant-test services
    for svc in "${!TEST_SVCS[@]}"; do
        if kubectl get svc "$svc" -n restaurant-test &> /dev/null; then
            TOTAL=$((TOTAL + 1))
            pid=${SVC_PIDS[$svc]:-0}
            if kill -0 "$pid" 2>/dev/null; then
                RUNNING=$((RUNNING + 1))
            else
                ports="${TEST_SVCS[$svc]}"
                kubectl port-forward -n restaurant-test "svc/$svc" $ports > /dev/null 2>&1 &
                SVC_PIDS[$svc]=$!
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

    # istio-system monitoring
    for svc in "${!ISTIO_SVCS[@]}"; do
        if kubectl get svc "$svc" -n istio-system &> /dev/null; then
            TOTAL=$((TOTAL + 1))
            pid=${SVC_PIDS[$svc]:-0}
            if kill -0 "$pid" 2>/dev/null; then
                RUNNING=$((RUNNING + 1))
            else
                ports="${ISTIO_SVCS[$svc]}"
                kubectl port-forward -n istio-system "svc/$svc" $ports > /dev/null 2>&1 &
                SVC_PIDS[$svc]=$!
                RUNNING=$((RUNNING + 1))
                RESTARTED=$((RESTARTED + 1))
            fi
        fi
    done

    # ArgoCD
    if kubectl get svc argocd-server -n argocd &> /dev/null; then
        TOTAL=$((TOTAL + 1))
        pid=${SVC_PIDS["argocd-server"]:-0}
        if kill -0 "$pid" 2>/dev/null; then
            RUNNING=$((RUNNING + 1))
        else
            kubectl port-forward -n argocd svc/argocd-server 9088:80 > /dev/null 2>&1 &
            SVC_PIDS["argocd-server"]=$!
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

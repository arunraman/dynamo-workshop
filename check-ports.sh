#!/bin/bash
# Port Verification and Diagnostic Script for Dynamo Workshop
# Checks user's assigned ports, availability, and running services

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Source workshop environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/workshop-env.sh" ]; then
    source "$SCRIPT_DIR/workshop-env.sh" 2>/dev/null
fi

# Print header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Dynamo Workshop - Port Diagnostic Tool                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Display user info
echo -e "${BLUE}👤 User Information${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Username:     $USER"
echo "  UID:          $(id -u)"
echo "  Home:         $HOME"
echo "  Namespace:    ${NAMESPACE:-Not set}"
echo ""

# Display assigned ports
echo -e "${BLUE}📋 Your Assigned Ports${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  JupyterLab:        ${USER_JUPYTER_PORT:-Not set}"
echo "  Frontend (Lab 1):  ${USER_FRONTEND_PORT:-Not set}"
echo "  Frontend (Lab 2):  ${USER_FRONTEND2_PORT:-Not set}"
echo "  Prometheus:        ${USER_PROMETHEUS_PORT:-Not set}"
echo "  Grafana:           ${USER_GRAFANA_PORT:-Not set}"
echo ""

# Function to check port status
check_port() {
    local port=$1
    local service=$2

    if [ -z "$port" ] || [ "$port" = "Not set" ]; then
        echo -e "  ${YELLOW}⚠${NC}  $service: Port not configured"
        return
    fi

    # Check if port is in use
    if command -v ss >/dev/null 2>&1; then
        local pid=$(ss -tlnp 2>/dev/null | grep ":${port} " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | head -1)
    elif command -v netstat >/dev/null 2>&1; then
        local pid=$(netstat -tlnp 2>/dev/null | grep ":${port} " | awk '{print $NF}' | cut -d'/' -f1 | head -1)
    elif command -v lsof >/dev/null 2>&1; then
        local pid=$(lsof -ti:$port 2>/dev/null | head -1)
    else
        echo -e "  ${YELLOW}?${NC}  $service (port $port): Cannot check (no ss/netstat/lsof available)"
        return
    fi

    if [ -n "$pid" ]; then
        local process=$(ps -p $pid -o comm= 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC}  $service (port $port): ${GREEN}IN USE${NC} by PID $pid ($process)"
    else
        echo -e "  ${YELLOW}○${NC}  $service (port $port): ${YELLOW}AVAILABLE${NC} (not in use)"
    fi
}

# Check all ports
echo -e "${BLUE}🔍 Port Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
check_port "$USER_JUPYTER_PORT" "JupyterLab"
check_port "$USER_FRONTEND_PORT" "Frontend (Lab 1)"
check_port "$USER_FRONTEND2_PORT" "Frontend (Lab 2)"
check_port "$USER_PROMETHEUS_PORT" "Prometheus"
check_port "$USER_GRAFANA_PORT" "Grafana"
echo ""

# Check JupyterLab status
echo -e "${BLUE}📓 JupyterLab Status${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "$SCRIPT_DIR/.jupyter.pid" ]; then
    JUPYTER_PID=$(cat "$SCRIPT_DIR/.jupyter.pid")
    if kill -0 $JUPYTER_PID 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} JupyterLab is running (PID: $JUPYTER_PID)"
        echo "    Access at: http://localhost:8888 (via SSH tunnel)"
        if [ -f "$SCRIPT_DIR/.jupyter.log" ]; then
            echo "    Logs: $SCRIPT_DIR/.jupyter.log"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} JupyterLab PID file exists but process is not running"
        echo "    Run: ./start-workshop.sh"
    fi
else
    echo -e "  ${YELLOW}○${NC} JupyterLab is not running"
    echo "    Run: ./start-workshop.sh"
fi
echo ""

# Check kubectl port-forwards
echo -e "${BLUE}🔀 Active kubectl Port-Forwards${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PORT_FORWARDS=$(ps aux | grep "kubectl port-forward" | grep -v grep | grep "$USER" || true)
if [ -n "$PORT_FORWARDS" ]; then
    echo "$PORT_FORWARDS" | while read line; do
        local pid=$(echo "$line" | awk '{print $2}')
        local port=$(echo "$line" | grep -oP '\d+:\d+' | head -1)
        echo -e "  ${GREEN}✓${NC} PID $pid: $port"
    done
else
    echo -e "  ${YELLOW}○${NC} No active kubectl port-forwards"
fi
echo ""

# Check Python environment
echo -e "${BLUE}🐍 Python Environment${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -d "$SCRIPT_DIR/.venv" ]; then
    echo -e "  ${GREEN}✓${NC} Virtual environment exists at: $SCRIPT_DIR/.venv"

    # Check if uv is available
    if command -v uv >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} uv is installed: $(which uv)"
    else
        echo -e "  ${YELLOW}⚠${NC} uv not found in PATH"
    fi

    # Check if jupyter is installed
    if [ -f "$SCRIPT_DIR/.venv/bin/jupyter" ]; then
        echo -e "  ${GREEN}✓${NC} Jupyter is installed in venv"
    else
        echo -e "  ${YELLOW}⚠${NC} Jupyter not found in venv"
        echo "    Run: uv pip install -r requirements.txt"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Virtual environment not found"
    echo "    Run: uv venv"
fi
echo ""

# Check Kubernetes namespace
echo -e "${BLUE}☸️  Kubernetes Namespace${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v kubectl >/dev/null 2>&1; then
    if [ -n "$NAMESPACE" ]; then
        if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${NC} Namespace exists: $NAMESPACE"

            # Count pods
            POD_COUNT=$(kubectl get pods -n "$NAMESPACE" 2>/dev/null | grep -v NAME | wc -l)
            if [ "$POD_COUNT" -gt 0 ]; then
                echo "    Pods running: $POD_COUNT"
            else
                echo "    No pods currently running"
            fi
        else
            echo -e "  ${YELLOW}⚠${NC} Namespace does not exist: $NAMESPACE"
            echo "    Run: kubectl create namespace $NAMESPACE"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} NAMESPACE variable not set"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} kubectl not found in PATH"
fi
echo ""

# Cleanup commands
echo -e "${BLUE}🧹 Cleanup Commands${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Stop JupyterLab:"
if [ -f "$SCRIPT_DIR/.jupyter.pid" ]; then
    JUPYTER_PID=$(cat "$SCRIPT_DIR/.jupyter.pid")
    echo "    kill $JUPYTER_PID"
fi
echo "    pkill -f 'jupyter.*${USER_JUPYTER_PORT}'"
echo ""
echo "  Kill all kubectl port-forwards:"
echo "    pkill -f 'kubectl port-forward'"
echo ""
echo "  Kill SSH tunnels (run on local machine):"
echo "    pkill -f 'ssh.*workshop.*-L'"
echo ""
echo "  Restart environment:"
echo "    ./start-workshop.sh"
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if there are any issues
ISSUES=0
if [ -z "$USER_JUPYTER_PORT" ] || [ "$USER_JUPYTER_PORT" = "Not set" ]; then
    ((ISSUES++))
fi
if [ ! -d "$SCRIPT_DIR/.venv" ]; then
    ((ISSUES++))
fi

if [ $ISSUES -gt 0 ]; then
    echo -e "${YELLOW}⚠ Issues detected. Review the output above.${NC}"
    echo -e "${YELLOW}  Try running: source ~/dynamo-workshop/workshop-env.sh${NC}"
else
    echo -e "${GREEN}✓ Environment looks good!${NC}"
fi
echo ""


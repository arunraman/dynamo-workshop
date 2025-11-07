#!/bin/bash
# Workshop Environment Configuration
# Automatically configures user-specific ports based on UID to prevent conflicts
# in multi-user shared workstation environment

# Detect current UID
CURRENT_UID=$(id -u)

# Validate UID is in expected range (1000-1040)
if [ "$CURRENT_UID" -lt 1000 ] || [ "$CURRENT_UID" -gt 1040 ]; then
    echo "⚠️  Warning: UID $CURRENT_UID is outside the expected range (1000-1040)"
    echo "   Port calculations may conflict with system services"
fi

# Calculate port offset from base UID
PORT_OFFSET=$((CURRENT_UID - 1000))

# Calculate user-specific ports
export USER_JUPYTER_PORT=$((8888 + PORT_OFFSET))
export USER_FRONTEND_PORT=$((10000 + PORT_OFFSET))
export USER_FRONTEND2_PORT=$((11000 + PORT_OFFSET))
export USER_PROMETHEUS_PORT=$((19090 + PORT_OFFSET))
export USER_GRAFANA_PORT=$((13000 + PORT_OFFSET))

# Set Kubernetes namespace based on username
export NAMESPACE="dynamo-${USER}"

# Set workshop directory
export WORKSHOP_DIR="${HOME}/dynamo-workshop"

# Set up uv venv activation
if [ -d "${WORKSHOP_DIR}/.venv" ]; then
    export VIRTUAL_ENV="${WORKSHOP_DIR}/.venv"
    export PATH="${VIRTUAL_ENV}/bin:${PATH}"
fi

# Print configuration banner
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Dynamo Workshop - Multi-User Configuration            ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ User: ${USER} (UID: ${CURRENT_UID})"
echo "║ Namespace: ${NAMESPACE}"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ Your assigned ports:"
echo "║   JupyterLab:        ${USER_JUPYTER_PORT}"
echo "║   Frontend (Lab 1):  ${USER_FRONTEND_PORT}"
echo "║   Frontend (Lab 2):  ${USER_FRONTEND2_PORT}"
echo "║   Prometheus:        ${USER_PROMETHEUS_PORT}"
echo "║   Grafana:           ${USER_GRAFANA_PORT}"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ SSH Tunnel Command (run on your local machine):"
echo "║   ssh -L 8888:localhost:${USER_JUPYTER_PORT} \\"
echo "║       -L 10000:localhost:${USER_FRONTEND_PORT} \\"
echo "║       -L 11000:localhost:${USER_FRONTEND2_PORT} \\"
echo "║       ${USER}@<workstation-hostname>"
echo "╚════════════════════════════════════════════════════════════════╝"

# Check for port conflicts (non-blocking)
check_port_conflict() {
    local port=$1
    local service=$2
    if command -v ss >/dev/null 2>&1; then
        if ss -tuln | grep -q ":${port} "; then
            echo "⚠️  Warning: Port ${port} (${service}) appears to be in use"
            return 1
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            echo "⚠️  Warning: Port ${port} (${service}) appears to be in use"
            return 1
        fi
    fi
    return 0
}

# Quick port availability check (optional, doesn't block)
if [ "${WORKSHOP_CHECK_PORTS}" = "1" ]; then
    echo ""
    echo "Checking port availability..."
    check_port_conflict "$USER_JUPYTER_PORT" "JupyterLab"
    check_port_conflict "$USER_FRONTEND_PORT" "Frontend"
    check_port_conflict "$USER_FRONTEND2_PORT" "Frontend2"
    echo ""
fi

# Export helper function for notebooks
export -f check_port_conflict 2>/dev/null || true


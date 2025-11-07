#!/bin/bash
# SSH Tunnel Setup Script for Dynamo Workshop
# Automatically sets up all necessary SSH tunnels based on remote user's UID
#
# Usage: ./setup-tunnels.sh [username@]hostname
#
# Example: ./setup-tunnels.sh student01@workshop.example.com
#          ./setup-tunnels.sh workshop-server  (if SSH config is already set up)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Dynamo Workshop - SSH Tunnel Setup Script                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check arguments
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No hostname provided${NC}"
    echo ""
    echo "Usage: $0 [username@]hostname"
    echo ""
    echo "Examples:"
    echo "  $0 student01@workshop.example.com"
    echo "  $0 workshop-server"
    echo ""
    exit 1
fi

SSH_TARGET="$1"

echo -e "${YELLOW}→ Detecting remote user's UID...${NC}"

# Get UID from remote system
REMOTE_UID=$(ssh "$SSH_TARGET" 'id -u' 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$REMOTE_UID" ]; then
    echo -e "${RED}✗ Failed to connect to ${SSH_TARGET}${NC}"
    echo "  Please check:"
    echo "  - SSH access is configured"
    echo "  - Hostname/username is correct"
    echo "  - SSH keys are set up"
    exit 1
fi

echo -e "${GREEN}✓ Connected to ${SSH_TARGET}${NC}"
echo -e "  Remote UID: ${REMOTE_UID}"
echo ""

# Validate UID range
if [ "$REMOTE_UID" -lt 1000 ] || [ "$REMOTE_UID" -gt 1040 ]; then
    echo -e "${YELLOW}⚠ Warning: UID ${REMOTE_UID} is outside expected range (1000-1040)${NC}"
    echo "  Continuing anyway..."
    echo ""
fi

# Calculate ports based on UID
PORT_OFFSET=$((REMOTE_UID - 1000))
REMOTE_JUPYTER_PORT=$((8888 + PORT_OFFSET))
REMOTE_FRONTEND_PORT=$((10000 + PORT_OFFSET))
REMOTE_FRONTEND2_PORT=$((11000 + PORT_OFFSET))
REMOTE_PROMETHEUS_PORT=$((19090 + PORT_OFFSET))
REMOTE_GRAFANA_PORT=$((13000 + PORT_OFFSET))

echo -e "${BLUE}📋 Port Mapping${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Service              Local Port → Remote Port"
echo "  ─────────────────    ──────────────────────────"
echo "  JupyterLab           8888       → ${REMOTE_JUPYTER_PORT}"
echo "  Frontend (Lab 1)     10000      → ${REMOTE_FRONTEND_PORT}"
echo "  Frontend (Lab 2)     11000      → ${REMOTE_FRONTEND2_PORT}"
echo "  Prometheus           19090      → ${REMOTE_PROMETHEUS_PORT}"
echo "  Grafana              13000      → ${REMOTE_GRAFANA_PORT}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for existing tunnels
EXISTING_TUNNELS=$(ps aux | grep "ssh.*${SSH_TARGET}" | grep -v grep | grep -- "-L" || true)
if [ -n "$EXISTING_TUNNELS" ]; then
    echo -e "${YELLOW}⚠ Existing SSH tunnels detected to ${SSH_TARGET}${NC}"
    echo ""
    echo "$EXISTING_TUNNELS"
    echo ""
    echo -n "Kill existing tunnels and create new ones? [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "  Killing existing tunnels..."
        pkill -f "ssh.*${SSH_TARGET}.*-L" || true
        sleep 1
    else
        echo "  Keeping existing tunnels. Exiting."
        exit 0
    fi
fi

# Create SSH tunnel command
echo -e "${YELLOW}→ Establishing SSH tunnels...${NC}"

# Create tunnel with all port forwards
ssh -N -f \
    -L 8888:localhost:${REMOTE_JUPYTER_PORT} \
    -L 10000:localhost:${REMOTE_FRONTEND_PORT} \
    -L 11000:localhost:${REMOTE_FRONTEND2_PORT} \
    -L 19090:localhost:${REMOTE_PROMETHEUS_PORT} \
    -L 13000:localhost:${REMOTE_GRAFANA_PORT} \
    "$SSH_TARGET"

# Check if tunnel was established
sleep 1
if pgrep -f "ssh.*${SSH_TARGET}.*-L" > /dev/null; then
    echo -e "${GREEN}✓ SSH tunnels established successfully!${NC}"
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Tunnels Active                              ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} You can now access workshop services on your local machine:"
    echo -e "${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}   📓 JupyterLab:    http://localhost:8888"
    echo -e "${BLUE}║${NC}   🔧 Frontend API:  http://localhost:10000"
    echo -e "${BLUE}║${NC}   🔧 Frontend 2:    http://localhost:11000"
    echo -e "${BLUE}║${NC}   📊 Prometheus:    http://localhost:19090"
    echo -e "${BLUE}║${NC}   📈 Grafana:       http://localhost:13000"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} To close tunnels:  pkill -f 'ssh.*${SSH_TARGET}.*-L'"
    echo -e "${BLUE}║${NC} To check status:   ps aux | grep 'ssh.*${SSH_TARGET}' | grep -v grep"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
else
    echo -e "${RED}✗ Failed to establish SSH tunnels${NC}"
    echo "  Please check SSH configuration and try again"
    exit 1
fi


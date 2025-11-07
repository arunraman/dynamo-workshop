#!/bin/bash
# Dynamo Workshop Startup Script
# Starts JupyterLab with user-specific port configuration for multi-user environment

set -e

WORKSHOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$WORKSHOP_DIR"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              🚀 Starting Dynamo Workshop                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check for provisioned marker
if [ ! -f ".workshop_provisioned" ]; then
    echo "⚠️  Warning: Workshop environment not provisioned via Ansible"
    echo "   This may indicate incomplete setup. Proceeding anyway..."
    echo ""
fi

# Source workshop environment configuration
if [ -f "workshop-env.sh" ]; then
    source workshop-env.sh
else
    echo "❌ Error: workshop-env.sh not found"
    echo "   This file is required for port configuration"
    exit 1
fi

# Check if venv exists
if [ ! -d ".venv" ]; then
    echo "📦 Creating Python virtual environment with uv..."
    if ! command -v uv &> /dev/null; then
        echo "❌ Error: uv is not installed"
        echo "   Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi
    uv venv
    echo "✅ Virtual environment created"
    echo ""
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source .venv/bin/activate

# Check/install requirements
if [ ! -f ".venv/.requirements_installed" ]; then
    echo "📚 Installing Python dependencies with uv..."
    echo "   This may take a few minutes on first run..."
    uv pip install -r requirements.txt
    touch .venv/.requirements_installed
    echo "✅ Dependencies installed"
    echo ""
else
    # Quick check for missing packages
    if ! python -c "import jupyter" &> /dev/null; then
        echo "📚 Reinstalling dependencies..."
        uv pip install -r requirements.txt
        echo "✅ Dependencies updated"
        echo ""
    fi
fi

# Check if JupyterLab is already running
if lsof -Pi :${USER_JUPYTER_PORT} -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  JupyterLab is already running on port ${USER_JUPYTER_PORT}"
    echo ""
    echo "Options:"
    echo "  1. Connect to existing instance: http://localhost:${USER_JUPYTER_PORT}"
    echo "  2. Stop it first: pkill -f 'jupyter.*${USER_JUPYTER_PORT}'"
    echo ""
    exit 1
fi

# Start JupyterLab
echo "🎓 Starting JupyterLab on port ${USER_JUPYTER_PORT}..."
echo ""

# Launch JupyterLab in background and capture PID
nohup jupyter lab \
    --ip=0.0.0.0 \
    --port=${USER_JUPYTER_PORT} \
    --no-browser \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_remote_access=True \
    > .jupyter.log 2>&1 &

JUPYTER_PID=$!
echo $JUPYTER_PID > .jupyter.pid

# Wait a moment for JupyterLab to start
sleep 3

# Check if it's running
if ! kill -0 $JUPYTER_PID 2>/dev/null; then
    echo "❌ Error: JupyterLab failed to start"
    echo "   Check .jupyter.log for details"
    exit 1
fi

echo "✅ Workshop is ready!"
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                     Connection Information                      ║"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ JupyterLab Port: ${USER_JUPYTER_PORT}"
echo "║ Kubernetes Namespace: ${NAMESPACE}"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ 📡 SSH Tunnel Command (run on your local machine):"
echo "║"
echo "║   ssh -L 8888:localhost:${USER_JUPYTER_PORT} \\"
echo "║       -L 10000:localhost:${USER_FRONTEND_PORT} \\"
echo "║       -L 11000:localhost:${USER_FRONTEND2_PORT} \\"
echo "║       ${USER}@<workstation-hostname>"
echo "║"
echo "║ Then open: http://localhost:8888"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ 📚 Available labs:"
echo "║   • Lab 1: lab1/lab1-introduction-setup.md"
echo "║   • Lab 2: lab2/distributed_inference_tutorial.md"
echo "║   • Lab 3: lab3/lab3.2-wide-ep-deployment.md"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ 🛠️  Useful commands:"
echo "║   • Check logs: tail -f .jupyter.log"
echo "║   • Stop workshop: pkill -f 'jupyter.*${USER_JUPYTER_PORT}'"
echo "║   • Check ports: ./check-ports.sh"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""


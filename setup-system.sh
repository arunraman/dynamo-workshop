#!/bin/bash
# System Setup Script for Dynamo Workshop
# Fallback for manual setup if not using Ansible provisioning
#
# This script should be run by an administrator with sudo privileges
# to set up the shared workstation for multiple workshop users.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Dynamo Workshop - System Setup Script                   ║${NC}"
echo -e "${BLUE}║       (Manual/Non-Ansible Installation)                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: This script requires sudo/root privileges${NC}"
echo -e "${YELLOW}⚠️  Ansible provisioning is the recommended approach${NC}"
echo -e "${YELLOW}    See ANSIBLE_PROVISIONING.md for details${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root or with sudo${NC}"
    echo "  Usage: sudo $0"
    exit 1
fi

echo -e "${GREEN}✓ Running with appropriate privileges${NC}"
echo ""

# Confirm before proceeding
echo -n "Proceed with system setup? [y/N] "
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi
echo ""

# Detect OS
echo -e "${BLUE}→ Detecting operating system...${NC}"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
    echo -e "${GREEN}✓ Detected: $PRETTY_NAME${NC}"
else
    echo -e "${RED}✗ Cannot detect operating system${NC}"
    exit 1
fi
echo ""

# Install system dependencies
echo -e "${BLUE}→ Installing system dependencies...${NC}"

if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    apt-get update
    apt-get install -y \
        python3.11 \
        python3.11-venv \
        python3-pip \
        kubectl \
        curl \
        git \
        vim \
        build-essential \
        lsof \
        net-tools \
        software-properties-common

    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]]; then
    yum install -y epel-release
    yum install -y \
        python3.11 \
        python3-pip \
        kubectl \
        curl \
        git \
        vim \
        gcc \
        lsof \
        net-tools

    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
else
    echo -e "${YELLOW}⚠ Unsupported OS: $OS${NC}"
    echo "  Please install dependencies manually:"
    echo "  - Python 3.11"
    echo "  - kubectl"
    echo "  - helm"
    echo "  - curl, git, vim, build tools"
    echo ""
    echo -n "Continue anyway? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ System dependencies installed${NC}"
echo ""

# Install uv
echo -e "${BLUE}→ Installing uv (Python package manager)...${NC}"

if command -v uv &> /dev/null; then
    echo -e "${GREEN}✓ uv is already installed${NC}"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to system PATH
    cat > /etc/profile.d/uv.sh << 'EOF'
export PATH="/usr/local/bin:$PATH"
EOF

    chmod 644 /etc/profile.d/uv.sh

    # Make uv available in current session
    export PATH="/usr/local/bin:$PATH"

    if command -v uv &> /dev/null; then
        echo -e "${GREEN}✓ uv installed successfully${NC}"
    else
        echo -e "${RED}✗ Failed to install uv${NC}"
        echo "  Try manual installation: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
fi
echo ""

# Create shared model cache directory
echo -e "${BLUE}→ Creating shared model cache directory...${NC}"

MODEL_CACHE="/data/huggingface-cache"

if [ -d "$MODEL_CACHE" ]; then
    echo -e "${YELLOW}⚠ Directory already exists: $MODEL_CACHE${NC}"
else
    mkdir -p "$MODEL_CACHE"
    echo -e "${GREEN}✓ Created: $MODEL_CACHE${NC}"
fi

# Set permissions
chmod 2775 "$MODEL_CACHE"
chown root:users "$MODEL_CACHE" 2>/dev/null || chown root:users "$MODEL_CACHE" || true

# Set ACL if available
if command -v setfacl &> /dev/null; then
    setfacl -d -m g:users:rwx "$MODEL_CACHE" 2>/dev/null || true
    echo -e "${GREEN}✓ Set permissions with ACL${NC}"
else
    echo -e "${YELLOW}⚠ ACL not available, using basic permissions${NC}"
fi

echo -e "${GREEN}✓ Model cache directory configured${NC}"
echo "  Path: $MODEL_CACHE"
echo "  Permissions: 2775 (rwxrwsr-x)"
echo ""

# System setup complete
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              System Setup Complete                             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo "1. Per-User Setup (for each workshop user):"
echo "   Run as the user (not root):"
echo ""
echo "   # Create workshop directory"
echo "   mkdir -p ~/dynamo-workshop"
echo "   cd ~/dynamo-workshop"
echo ""
echo "   # Copy workshop materials"
echo "   # (from your workshop repo)"
echo ""
echo "   # Create Python venv"
echo "   uv venv"
echo ""
echo "   # Install dependencies"
echo "   uv pip install -r requirements.txt"
echo ""
echo "   # Add environment script to .bashrc"
echo "   echo 'source ~/dynamo-workshop/workshop-env.sh' >> ~/.bashrc"
echo ""
echo "2. Create Kubernetes Namespaces:"
echo "   For each user (replace student01 with actual username):"
echo ""
echo "   kubectl create namespace dynamo-student01"
echo "   kubectl create namespace dynamo-student02"
echo "   # ... etc"
echo ""
echo "3. Test Setup:"
echo "   As a test user, run:"
echo ""
echo "   cd ~/dynamo-workshop"
echo "   ./start-workshop.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${YELLOW}💡 For automated setup of multiple users, use Ansible:${NC}"
echo "   See: ANSIBLE_PROVISIONING.md"
echo ""
echo -e "${BLUE}📚 Documentation:${NC}"
echo "   - Main README: README.md"
echo "   - Ansible guide: ANSIBLE_PROVISIONING.md"
echo "   - Tunneling guide: TUNNELING.md"
echo ""


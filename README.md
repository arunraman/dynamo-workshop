# Dynamo Workshop

Welcome to the Dynamo Workshop! This hands-on workshop will guide you through deploying and managing NVIDIA's Dynamo - a datacenter-scale distributed inference serving framework.

## Overview

Dynamo is a high-performance, distributed LLM inference serving framework that supports multiple backends (vLLM, SGLang, TensorRT-LLM) and is designed for datacenter-scale deployments. This workshop focuses on Kubernetes-based deployments and advanced features.

## Workshop Structure

### Lab 1: Introduction and Docker-Based Deployment
- Understanding Dynamo architecture
- Setting up local development environment
- Docker-based aggregated deployment
- Backend engine selection (vLLM/SGLang/TensorRT-LLM)
- Benchmarking with AI-Perf

### Lab 2: Advanced Kubernetes Deployment
- Deploying Dynamo on Kubernetes
- Installing Dynamo operator
- Aggregated and disaggregated serving topologies
- Multi-model deployment with shared frontend
- AI Configurator for optimal configurations

### Lab 3: Expert Parallelism for MoE Models
- **Lab 3.1**: Expert Parallelism Foundations
  - Understanding parallelism strategies (DP, TP, PP, SP, EP)
  - MoE architecture and expert routing mechanisms
  - Wide EP, Deep EP, and Dynamic EP (EPLB)
  - Large-scale deployment insights (GB200 NVL72)
- **Lab 3.2**: Wide EP Production Deployment
  - Kubernetes deployment with Dynamo Operator
  - Multi-node SGLang and TensorRT-LLM configurations
  - EPLB load balancing strategies
  - Monitoring and troubleshooting

## Prerequisites

Before starting this workshop, ensure you have:

- **Local Setup:**
  - Python 3.10 or higher
  - Docker and Docker Compose
  - `kubectl` command-line tool
  - Access to a GPU (for local testing)

- **Kubernetes Cluster:**
  - Access to a Kubernetes cluster with GPU nodes
  - `kubectl` configured to access your cluster
  - Sufficient GPU resources (recommended: 2+ NVIDIA GPUs)

- **Knowledge:**
  - Basic understanding of Kubernetes concepts
  - Familiarity with Python
  - Basic understanding of LLMs and inference

## Multi-User Shared Workstation Setup

**For Workshop Participants:** If you're attending a workshop using a shared workstation, follow these instructions instead of the "Getting Started" options below.

### Architecture Overview

The workshop uses a shared workstation where:
- ~30 users run concurrently with individual user accounts
- Each user has unique port assignments based on UID (1000-1040)
- JupyterLab and services run natively (bare metal, not Docker)
- Python environments managed with `uv` for fast dependency installation
- Kubernetes namespaces are pre-created per user

### Port Allocation Scheme

Your ports are automatically calculated based on your UID:

| Service | Port Formula | Example (UID=1005) |
|---------|-------------|-------------------|
| JupyterLab | 8888 + (UID - 1000) | 8893 |
| Frontend (Lab 1) | 10000 + (UID - 1000) | 10005 |
| Frontend (Lab 2) | 11000 + (UID - 1000) | 11005 |
| Prometheus | 19090 + (UID - 1000) | 19095 |
| Grafana | 13000 + (UID - 1000) | 13005 |

**Note:** Your environment variables are automatically set via `workshop-env.sh` which is sourced in your `.bashrc`.

### Quick Start (Workshop Day)

#### Step 1: SSH into the Workstation

```bash
ssh your-username@workshop-hostname
```

#### Step 2: Start the Workshop Environment

```bash
cd ~/dynamo-workshop
./start-workshop.sh
```

This will:
- Load your user-specific port configuration
- Activate your Python virtual environment (managed by uv)
- Start JupyterLab on your assigned port
- Display connection information

#### Step 3: Set Up SSH Tunnels (On Your Local Machine)

From your **local machine** (not the workstation), run:

```bash
# Automatic setup (recommended)
./setup-tunnels.sh your-username@workshop-hostname

# Or manually (see TUNNELING.md for details)
```

The tunnel script will:
- Detect your remote UID
- Calculate your assigned ports
- Set up all necessary SSH tunnels
- Display connection URLs

#### Step 4: Access JupyterLab

Open your browser to: **http://localhost:8888**

(The local port is always 8888, regardless of your remote port)

#### Step 5: Start Lab 1

Navigate to `lab1/lab1-introduction-setup.md` in JupyterLab and begin!

### Checking Your Configuration

At any time, you can check your port assignments:

```bash
# On the workstation
source ~/dynamo-workshop/workshop-env.sh

# Or run the verification script
~/dynamo-workshop/check-ports.sh
```

### SSH Tunnel Guide

For detailed SSH tunneling instructions, including:
- Manual setup
- VS Code Remote SSH configuration
- Troubleshooting port conflicts
- Keeping tunnels alive

See: **[TUNNELING.md](TUNNELING.md)**

### Python Environment

The workshop uses **uv** for Python package management:
- Fast dependency installation (much faster than pip)
- Virtual environments pre-created via Ansible
- All requirements pre-installed
- To add packages: `uv pip install package-name`

### Troubleshooting

**Port conflicts:**
```bash
# Check what's using your ports
./check-ports.sh

# Kill stuck processes
pkill -f 'jupyter.*YOUR_PORT'
pkill -f 'port-forward'
```

**Environment issues:**
```bash
# Reload environment
source ~/dynamo-workshop/workshop-env.sh

# Reinstall dependencies
cd ~/dynamo-workshop
uv pip install -r requirements.txt
```

**For Administrators:** See [ANSIBLE_PROVISIONING.md](ANSIBLE_PROVISIONING.md) for setup instructions.

---

## Getting Started

**Note:** These options are for **single-user local development**. Workshop participants should use the "Multi-User Shared Workstation Setup" above.

### Option 1: Using Docker (Single-User Local Development)

1. Clone this repository:
```bash
git clone <repository-url>
cd dynamo-workshop
```

2. Start the workshop environment:
```bash
./start-workshop.sh
```

3. Open your browser to `http://localhost:8888`

4. Navigate to the lab notebooks and start with Lab 1

5. When finished, stop the environment:
```bash
docker compose down
```

### Option 2: Local Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd dynamo-workshop
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Start JupyterLab:
```bash
jupyter lab
```

4. Navigate to Lab 1 in the JupyterLab interface and start with `lab1/lab1-introduction-setup.ipynb`

## Workshop Labs

| Lab | Topic | Duration | Notebook |
|-----|-------|----------|----------|
| Lab 1 | Introduction and Docker-Based Deployment | 90 min | [lab1-introduction-setup.ipynb](lab1/lab1-introduction-setup.ipynb) |
| Lab 2 | Advanced Kubernetes Deployment | 120 min | [lab2-kubernetes-deployment.ipynb](lab2/lab2-kubernetes-deployment.ipynb) |
| Lab 3.1 | Expert Parallelism Foundations | 45-60 min | [lab3.1-expert-parallelism-foundations.ipynb](lab3/lab3.1-expert-parallelism-foundations.ipynb) |
| Lab 3.2 | Wide EP Production Deployment | 60-90 min | [lab3.2-wide-ep-deployment.ipynb](lab3/lab3.2-wide-ep-deployment.ipynb) |

## Resources

- [Dynamo GitHub Repository](https://github.com/ai-dynamo/dynamo)
- [Dynamo Documentation](https://docs.nvidia.com/dynamo/latest)
- [Dynamo Quickstart Guide](https://github.com/ai-dynamo/dynamo#installation)

## Support

For issues or questions:
- Check the [Dynamo GitHub Issues](https://github.com/ai-dynamo/dynamo/issues)
- Refer to the official documentation
- Ask your workshop instructor

## License

This workshop is provided under the Apache-2.0 license, consistent with the Dynamo project.

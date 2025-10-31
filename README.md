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

## Getting Started

### Option 1: Using Docker (Recommended)

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
docker-compose down
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

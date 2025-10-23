# Dynamo Workshop

Welcome to the Dynamo Workshop! This hands-on workshop will guide you through deploying and managing NVIDIA's Dynamo - a datacenter-scale distributed inference serving framework.

## Overview

Dynamo is a high-performance, distributed LLM inference serving framework that supports multiple backends (vLLM, SGLang, TensorRT-LLM) and is designed for datacenter-scale deployments. This workshop focuses on Kubernetes-based deployments and advanced features.

## Workshop Structure

### Lab 1: Introduction and Local Setup
- Understanding Dynamo architecture
- Setting up local development environment
- Running Dynamo components locally
- Basic inference requests

### Lab 2: Kubernetes Deployment
- Deploying Dynamo on Kubernetes
- Configuring etcd and NATS
- Deploying workers with different engines
- Load balancing and routing

### Lab 3: Advanced Features and Optimization
- Disaggregated serving (KV cache separation)
- Multi-model serving
- Monitoring and observability
- Performance tuning and benchmarking

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

1. Clone this repository:
```bash
git clone <repository-url>
cd dynamo-workshop
```

2. Install Jupyter:
```bash
pip install jupyter notebook ipykernel
```

3. Start with Lab 1:
```bash
cd lab1
jupyter notebook lab1-introduction-setup.ipynb
```

## Workshop Labs

| Lab | Topic | Duration | Notebook |
|-----|-------|----------|----------|
| Lab 1 | Introduction and Local Setup | 60 min | [lab1-introduction-setup.ipynb](lab1/lab1-introduction-setup.ipynb) |
| Lab 2 | Kubernetes Deployment | 90 min | [lab2-kubernetes-deployment.ipynb](lab2/lab2-kubernetes-deployment.ipynb) |
| Lab 3 | Advanced Features | 90 min | [lab3-advanced-features.ipynb](lab3/lab3-advanced-features.ipynb) |

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

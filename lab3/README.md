# Lab 3: Expert Parallelism for MoE Models

This lab covers Expert Parallelism (EP) for Mixture-of-Experts models, from foundations to production deployment.

## Objectives

- Understand parallelism strategies (DP, TP, PP, SP, EP)
- Learn MoE architecture and expert routing mechanisms
- Deploy Wide EP with SGLang and TensorRT-LLM
- Configure EPLB (Expert Parallelism Load Balancer)
- Monitor and optimize multi-node MoE deployments

## Files

- `lab3.1-expert-parallelism-foundations.ipynb` - Conceptual foundations and simulations
- `lab3.2-wide-ep-deployment.ipynb` - Production deployment guide
- `configs/` - TensorRT-LLM and SGLang configuration files
- `k8s/` - Kubernetes deployment manifests
- `images/` - Diagrams and visualizations

## Prerequisites

- Completed Lab 1 and Lab 2
- Multi-GPU cluster (minimum 4 GPUs recommended)
- High-bandwidth interconnect (InfiniBand or NVLink recommended)
- NATS and etcd running (from Lab 2)

## Getting Started

1. Start with Lab 3.1 to understand the concepts:
   ```bash
   jupyter lab lab3.1-expert-parallelism-foundations.ipynb
   ```
   Or use the Docker environment: `./start-workshop.sh`

2. Navigate to `lab3/lab3.1-expert-parallelism-foundations.ipynb` in the JupyterLab file browser

3. After completing Lab 3.1, proceed to Lab 3.2 for deployment

4. Follow the sections in order

## Expected Outcomes

By the end of this lab, you will have:
- Deep understanding of Expert Parallelism concepts
- Hands-on experience with MoE routing simulations
- Production-ready Wide EP deployments
- Knowledge of EPLB load balancing strategies
- Ability to monitor and troubleshoot multi-node MoE systems

## Time Estimate

- Lab 3.1: ~45-60 minutes
- Lab 3.2: ~60-90 minutes

## Next Steps

After completing this lab, you'll be ready to deploy production-scale MoE models with optimal expert parallelism configurations.


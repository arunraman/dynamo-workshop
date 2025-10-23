# Lab 3: Wide EP Deployments and KVBM

This lab explores datacenter-scale deployments with wide EP and advanced KV cache management using KVBM.

## Objectives

- Deploy Dynamo across multiple nodes (wide EP deployments)
- Implement KVBM (KV Cache Bandwidth Manager)
- Measure and compare performance of different deployment strategies
- Optimize for production-scale workloads

## Files

- `lab3-advanced-features.ipynb` - Main lab notebook

Advanced configurations and manifests will be created during the lab.

## Prerequisites

- Completed Lab 1 and Lab 2
- Multi-node Kubernetes cluster with GPUs
- Understanding of distributed systems
- Network with sufficient bandwidth between nodes

## Getting Started

1. Verify multi-node cluster setup:
   ```bash
   kubectl get nodes
   kubectl get nodes -o wide
   ```

2. Open the Jupyter notebook:
   ```bash
   jupyter notebook lab3-advanced-features.ipynb
   ```

3. Follow the sections in order

## Expected Outcomes

By the end of this lab, you will have:
- Wide EP deployment across multiple nodes
- KVBM configured and optimized
- Performance comparison data
- Production-ready deployment knowledge

## Time Estimate

~120 minutes

## Workshop Completion

Congratulations on completing the Dynamo Workshop!


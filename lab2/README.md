# Lab 2: Advanced Kubernetes Deployment

This lab covers deploying Dynamo on Kubernetes with aggregated and disaggregated serving topologies.

## Objectives

- Deploy Dynamo on Kubernetes
- Install and use the Dynamo Kubernetes operator
- Deploy aggregated and disaggregated serving topologies
- Deploy multiple models with a shared frontend
- Use AI Configurator for optimal configurations

## Files

- `lab2-kubernetes-deployment.ipynb` - Main lab notebook

Kubernetes manifests and configurations will be created during the lab.

## Prerequisites

- Completed Lab 1
- Access to Kubernetes cluster with GPU nodes
- kubectl configured
- Basic Kubernetes knowledge

## Getting Started

1. Ensure your Kubernetes cluster is accessible:
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

2. Open the Jupyter notebook:
   ```bash
   jupyter notebook lab2-kubernetes-deployment.ipynb
   ```

3. Follow the sections in order

## Expected Outcomes

By the end of this lab, you will have:
- Dynamo running on Kubernetes
- Understanding of aggregated vs disaggregated topologies
- Multi-model deployment experience
- Knowledge of the Dynamo operator

## Time Estimate

~120 minutes

## Next Lab

Proceed to Lab 3 for wide EP deployments and KVBM


# Lab 1: Introduction and Kubernetes-Based Deployment

This lab introduces Dynamo and guides you through setting up a namespace-scoped Kubernetes deployment on a shared cluster.

## Objectives

- Set up your personal namespace in the shared Kubernetes cluster
- Deploy namespace-scoped Dynamo platform (operator, etcd, NATS)
- Deploy your first model using aggregated serving with vLLM
- Test with OpenAI-compatible API
- Benchmark the deployment using AI-Perf

## Files

- `lab1-introduction-setup.md` - Main lab guide with detailed instructions
- `lab1-monitoring.md` - Optional extension for Prometheus and Grafana monitoring
- `agg_router.yaml` - Kubernetes deployment manifest for aggregated serving

## Prerequisites

- Kubernetes cluster access (kubeconfig provided by instructor)
- `kubectl` installed (version 1.24+)
- `helm` 3.x installed
- HuggingFace token from [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)

## Getting Started

1. Verify your kubeconfig is set up correctly:
   ```bash
   kubectl version --client
   kubectl cluster-info
   ```

2. Follow the guide in `lab1-introduction-setup.md`

3. Start with Section 1 (Environment Setup) and proceed through each section in order

4. Use the Appendix for complete command reference

## Expected Outcomes

By the end of this lab, you will have:
- Your own namespace with a namespace-scoped Dynamo operator
- A working Dynamo deployment serving a model via aggregated serving
- Understanding of Kubernetes-based aggregated serving architecture
- Experience with DynamoGraphDeployment CRD
- Baseline performance benchmarks using AI-Perf
- **(Optional)** Prometheus and Grafana monitoring stack with Dynamo dashboards

## Time Estimate

- Main lab: ~90 minutes
- Monitoring extension: +30 minutes (optional)

## Key Concepts

- **Namespace-scoped operator**: Dynamo operator that only manages resources in your namespace (safe for shared clusters)
- **Aggregated serving**: All model layers on same GPU(s), simpler topology
- **KV-cache routing**: Intelligent load balancing based on KV cache state
- **DynamoGraphDeployment**: Kubernetes Custom Resource for defining inference deployments

## Next Lab

Proceed to Lab 2 for disaggregated serving and advanced configurations


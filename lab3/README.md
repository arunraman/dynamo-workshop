# Lab 3: Expert Parallelism for MoE Models

This lab demonstrates deploying Mixture-of-Experts (MoE) models with Expert Parallelism using Dynamo on Kubernetes.

## What is Expert Parallelism?

Expert Parallelism (EP) distributes the experts of MoE models across multiple GPUs. For example, DeepSeek-R1 has 256 experts, and EP allows you to spread these experts across 8-64 GPUs, enabling efficient large-scale deployment.

**Key Concepts:**
- **Wide EP**: Horizontal scaling of experts across many GPUs
- **EPLB**: Dynamic load balancing to prevent expert hotspots
- **Disaggregated Serving**: Separate prefill and decode workers for efficiency

## Lab Structure

- **Lab 3.1**: `lab3.1-expert-parallelism-foundations.ipynb` - Conceptual foundations (45-60 min)
- **Lab 3.2**: `lab3.2-wide-ep-deployment.ipynb` - Hands-on deployment (60-90 min)

This README provides quick deployment commands. **For detailed explanations, use the notebooks.**

## Prerequisites

- Kubernetes cluster with GPU support
- `kubectl` and `helm` 3.x installed
- Dynamo Operator (installed in Lab 1 or Lab 2)
- HuggingFace token from [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
- Minimum 16 GPUs (2 nodes × 8 GPUs recommended)

## Step 1: Verify Dynamo Platform

**Note:** If you completed Lab 1 or Lab 2, Dynamo should already be installed. Let's verify:

```sh
export NAMESPACE=dynamo-workshop

# Check if platform is running
kubectl get pods -n ${NAMESPACE}

# Expected: dynamo-operator, etcd, and nats pods Running
```

**If not installed**, install following Lab 2 instructions:

```sh
export RELEASE_VERSION=0.6.0

# Install CRDs (skip if already exists)
helm fetch https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-crds-${RELEASE_VERSION}.tgz
helm install dynamo-crds dynamo-crds-${RELEASE_VERSION}.tgz --namespace default

# Install platform
kubectl create namespace ${NAMESPACE} 2>/dev/null || echo "Namespace exists"
helm fetch https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-platform-${RELEASE_VERSION}.tgz
helm install dynamo-platform dynamo-platform-${RELEASE_VERSION}.tgz --namespace ${NAMESPACE}

# Wait for pods to be ready
kubectl get pods -n ${NAMESPACE} -w
```

## Step 2: Build Custom Docker Image with DeepEP

DeepSeek-R1 deployment requires a custom image with DeepEP (SGLang's Expert Parallelism backend):

```sh
cd /path/to/dynamo  # Adjust to your Dynamo repo location

# Checkout stable version
git checkout v0.6.0

# Build image (takes 30-60 minutes)
docker build \
  -f container/Dockerfile.sglang-wideep \
  -t dynamo-wideep:0.6.0 \
  .

# Verify image was created
docker images | grep dynamo-wideep
```

**For multi-node deployments** (optional), push to registry:

```sh
# Tag and push
docker tag dynamo-wideep:0.6.0 your-registry/dynamo-wideep:0.6.0
docker push your-registry/dynamo-wideep:0.6.0

# Update manifests with your registry
cd /path/to/dynamo-workshop/lab3
sed -i 's|dynamo-wideep:0.6.0|your-registry/dynamo-wideep:0.6.0|g' k8s/*.yaml
```

## Step 3: Create HuggingFace Secret

```sh
export HF_TOKEN=your_huggingface_token
export NAMESPACE=dynamo-workshop

kubectl create secret generic hf-token-secret \
  --from-literal=HF_TOKEN=${HF_TOKEN} \
  --namespace ${NAMESPACE}

# Verify secret
kubectl get secret hf-token-secret -n ${NAMESPACE}
```

## Step 4: Deploy DeepSeek-R1 with Wide EP

Choose the appropriate manifest for your hardware:

### Option A: Single-Node Workers (Recommended)

**Hardware**: 2 nodes × 8 GPUs each = 16 GPUs total

```sh
cd /path/to/dynamo-workshop/lab3

# Deploy
kubectl apply -f k8s/deepseek-r1-8gpu-singlenode.yaml -n ${NAMESPACE}

# Monitor deployment (takes 5-10 minutes for model download)
kubectl get pods -n ${NAMESPACE} -w
```

**Architecture:**
- Prefill Worker: 1 pod × 8 GPUs (TP=8, EP=8)
- Decode Worker: 1 pod × 8 GPUs (TP=8, DP=8, EP=8)
- Fast NVLink communication within each node

### Option B: Multi-Node Workers (Advanced)

**Hardware**: 4 nodes × 4 GPUs each = 16 GPUs total (different hardware than Option A!)

```sh
kubectl apply -f k8s/deepseek-r1-16gpu-multinode.yaml -n ${NAMESPACE}
kubectl get pods -n ${NAMESPACE} -w
```

**Architecture:**
- Prefill Worker: 2 pods × 4 GPUs each (cross-node TP=8, EP=8)
- Decode Worker: 2 pods × 4 GPUs each (cross-node TP=8, DP=8, EP=8)
- Requires InfiniBand or high-bandwidth interconnect

## Step 5: Test the Deployment

```sh
# Port forward to access frontend
kubectl port-forward -n ${NAMESPACE} svc/deepseek-r1-wideep-frontend 8000:8000
```

In a new terminal, test the endpoint:

```sh
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1",
    "messages": [{"role": "user", "content": "Explain MoE models in one sentence"}],
    "max_tokens": 100
  }'
```

**Expected response:**
```json
{
  "id": "chatcmpl-...",
  "choices": [{
    "message": {
      "content": "Mixture-of-Experts models activate only a subset of experts per token...",
      "role": "assistant"
    },
    "finish_reason": "stop"
  }],
  "usage": {"prompt_tokens": 10, "completion_tokens": 50, "total_tokens": 60}
}
```

## Configuration Reference

### Available Manifests

| Manifest | Hardware | Description |
|----------|----------|-------------|
| `deepseek-r1-8gpu-singlenode.yaml` | 2 nodes × 8 GPUs | Recommended: Simple, fast NVLink |
| `deepseek-r1-16gpu-multinode.yaml` | 4 nodes × 4 GPUs | Advanced: Multi-node coordination |

### Key Parameters

Edit the YAML manifests to customize:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--tp-size` | 8 | Tensor parallelism (model weights split) |
| `--ep-size` | 8 | Expert parallelism (256 experts / 8 GPUs = 32 per GPU) |
| `--dp-size` | 8 | Data parallelism (decode only, for batch processing) |
| `--ep-num-redundant-experts` | 32 | Hot expert replication for load balancing |
| `--mem-fraction-static` | 0.85 | GPU memory fraction to use |

### Adjusting for Different Hardware

**For 8 GPUs total** (single node):

```yaml
PrefillWorker:
  multinode:
    nodeCount: 1
  resources:
    limits:
      gpu: "4"
  args:
    - --tp-size
    - "4"
    - --ep-size
    - "4"
```

**For 32 GPUs total** (4 nodes × 8 GPUs):

```yaml
PrefillWorker:
  multinode:
    nodeCount: 4
  resources:
    limits:
      gpu: "8"
  args:
    - --tp-size
    - "16"
    - --ep-size
    - "16"
```

## Monitoring

### Check Deployment Status

```sh
# Check all pods
kubectl get pods -n ${NAMESPACE}

# Check logs
kubectl logs -n ${NAMESPACE} -l component=prefill --tail=50
kubectl logs -n ${NAMESPACE} -l component=decode --tail=50
kubectl logs -n ${NAMESPACE} -l component=frontend --tail=50

# Check deployment resource
kubectl get dynamographdeployment -n ${NAMESPACE}
```

### Monitor Expert Load Balancing

```sh
# Check EPLB activity
kubectl logs -n ${NAMESPACE} -l component=prefill | grep -i eplb

# Look for:
# - "EPLB initialized" (EPLB is active)
# - "Expert usage distribution" (load balancing stats)
# - "Replicating expert X" (hot expert replication)
```

### GPU Utilization

```sh
# Exec into worker pod
kubectl exec -it -n ${NAMESPACE} <worker-pod-name> -- nvidia-smi

# Check all GPUs are utilized
# With EP, all GPUs should show similar utilization
```

## Troubleshooting

### Image Pull Errors (`ImagePullBackOff`)

```sh
# Check pod details
kubectl describe pod <pod-name> -n ${NAMESPACE}

# Common causes:
# 1. Image not built yet - build with docker build command above
# 2. Image not available on other nodes - push to registry
# 3. Wrong image name in manifest - verify image name matches
```

### Insufficient GPU Resources

```sh
# Check GPU availability
kubectl get nodes -o json | jq -r '.items[] | "\(.metadata.name): \(.status.allocatable."nvidia.com/gpu" // "0") GPUs"'

# Solution: Adjust manifest to match available GPUs
# Edit k8s/*.yaml and reduce gpu count or nodeCount
```

### Workers Not Starting / OOM Errors

```sh
# Check pod logs
kubectl logs <pod-name> -n ${NAMESPACE}

# If OOM errors, reduce memory usage in manifest:
# - Lower --mem-fraction-static to 0.80
# - Reduce --ep-num-redundant-experts to 16
# - Increase GPU count per worker
```

### Model Download Stuck

```sh
# Check if HuggingFace token is valid
kubectl get secret hf-token-secret -n ${NAMESPACE} -o yaml

# Verify you have access to DeepSeek-R1 on HuggingFace
# Visit: https://huggingface.co/deepseek-ai/DeepSeek-R1
```

### Expert Load Imbalance

```sh
# Check EPLB logs
kubectl logs -n ${NAMESPACE} -l component=prefill | grep "Expert usage"

# If imbalanced, increase redundant experts in manifest:
# Change --ep-num-redundant-experts from 32 to 64
```

### Multi-Node Communication Issues

```sh
# Check InfiniBand status (if using IB)
kubectl exec <pod-name> -n ${NAMESPACE} -- ibstat

# Check NCCL logs
kubectl logs <pod-name> -n ${NAMESPACE} | grep NCCL

# Verify nodes can communicate
kubectl exec <pod-name> -n ${NAMESPACE} -- ping <other-node-ip>
```

## Cleanup

```sh
export NAMESPACE=dynamo-workshop

# Delete deployment
kubectl delete -f k8s/deepseek-r1-8gpu-singlenode.yaml -n ${NAMESPACE}
# OR
kubectl delete -f k8s/deepseek-r1-16gpu-multinode.yaml -n ${NAMESPACE}

# Delete secret
kubectl delete secret hf-token-secret -n ${NAMESPACE}

# (Optional) Uninstall platform if no longer needed
helm uninstall dynamo-platform -n ${NAMESPACE}
kubectl delete namespace ${NAMESPACE}
```

## Learning Resources

### Notebooks (Recommended)

- **Lab 3.1**: `lab3.1-expert-parallelism-foundations.ipynb` - Learn EP concepts
- **Lab 3.2**: `lab3.2-wide-ep-deployment.ipynb` - Step-by-step deployment guide

### External Resources

- [SGLang Large-Scale EP Blog](https://lmsys.org/blog/2025-05-05-large-scale-ep/)
- [NVIDIA NVL72 Wide-EP Blog](https://developer.nvidia.com/blog/scaling-large-moe-models-with-wide-expert-parallelism-on-nvl72-rack-scale-systems/)
- [DeepSeek-R1 on HuggingFace](https://huggingface.co/deepseek-ai/DeepSeek-R1)
- [Dynamo Documentation](https://github.com/ai-dynamo/dynamo)

## Next Steps

After completing this lab:
1. Benchmark performance with different EP configurations
2. Experiment with EPLB parameters
3. Try other MoE models (Mixtral, Qwen, DeepSeek-V3)
4. Explore TensorRT-LLM backend for production
5. Set up monitoring and observability

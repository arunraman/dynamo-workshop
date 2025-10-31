# Kubernetes Deployment Manifests

This directory contains Kubernetes manifests for deploying DeepSeek-R1 with Expert Parallelism using Dynamo's Kubernetes Operator.

## Prerequisites

1. **Dynamo Platform Installed**:
   ```bash
   helm install dynamo-platform nvidia/dynamo-platform --namespace dynamo-system --create-namespace
   ```

2. **HuggingFace Token Secret** (for model downloads):
   ```bash
   kubectl create secret generic hf-token-secret \
     --from-literal=HF_TOKEN=your_hf_token_here \
     -n dynamo
   ```

3. **GPU Nodes**: Ensure your cluster has GPU nodes with:
   - NVIDIA GPU Operator installed
   - InfiniBand or high-bandwidth networking (for multi-node)

## Deployment Options

### Option 1: SGLang Backend (`deepseek-r1-wideep.yaml`)

Deploy DeepSeek-R1 with SGLang backend, Expert Parallelism, and EPLB:

```bash
kubectl apply -f deepseek-r1-wideep.yaml
```

**Configuration**:
- 4 prefill nodes × 8 GPUs = 32 GPUs
- 4 decode nodes × 8 GPUs = 32 GPUs  
- TP=32, DP=32, DP attention enabled
- DeepEP backend with EPLB
- 32 redundant experts
- NIXL for KV transfer

### Option 2: TensorRT-LLM Backend (`deepseek-r1-trtllm.yaml`)

Deploy DeepSeek-R1 with TensorRT-LLM backend and FP8 quantization:

```bash
# First, create ConfigMap from YAML configs
kubectl create configmap trtllm-configs \
  --from-file=../configs/trtllm/ \
  -n dynamo

# Then deploy
kubectl apply -f deepseek-r1-trtllm.yaml
```

**Configuration**:
- 2 prefill nodes × 8 GPUs = 16 GPUs
- 2 decode nodes × 8 GPUs = 16 GPUs
- TP=16, EP=16, DP attention enabled
- FP8 KV cache (50% memory savings)
- CUDA graphs for decode optimization

## Monitoring Deployment

```bash
# Check deployment status
kubectl get dynamographdeployment -n dynamo

# Check pods
kubectl get pods -n dynamo -l app.kubernetes.io/name=deepseek-r1-wideep

# Check logs
kubectl logs -n dynamo -l component=prefill --tail=100
kubectl logs -n dynamo -l component=decode --tail=100

# Check frontend
kubectl logs -n dynamo -l component=frontend
```

## Testing the Deployment

```bash
# Get the frontend service
kubectl get svc -n dynamo

# Port-forward to access locally
kubectl port-forward -n dynamo svc/deepseek-r1-wideep-frontend 8000:8000

# Test with curl
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1",
    "messages": [
      {"role": "user", "content": "Explain quantum computing"}
    ],
    "max_tokens": 200
  }'
```

## Scaling

### Horizontal Scaling (More Replicas)

To add more worker replicas:

```yaml
spec:
  services:
    PrefillWorker:
      replicas: 2  # Increase from 1 to 2
```

### Vertical Scaling (More GPUs per Node)

To use more GPUs per node:

```yaml
spec:
  services:
    PrefillWorker:
      multinode:
        nodeCount: 4
      resources:
        limits:
          gpu: "8"  # Already at 8 GPUs per node
```

And update the parallelism parameters:

```yaml
args:
  - --tp-size
  - "32"  # Adjust based on total GPUs
```

## Customization

### Adjusting for Fewer GPUs

For a smaller deployment (e.g., 8 GPUs total):

```yaml
spec:
  services:
    PrefillWorker:
      multinode:
        nodeCount: 1  # Single node
      resources:
        limits:
          gpu: "4"  # 4 GPUs for prefill
      args:
        - --tp-size
        - "4"
        - --dp-size
        - "4"
        - --ep-num-redundant-experts
        - "8"  # Reduce redundant experts
```

### Using Different Models

Replace the model path in the args:

```yaml
args:
  - --model-path
  - deepseek-ai/DeepSeek-R1-Distill-Llama-8B  # Smaller model
```

### Memory Tuning

If experiencing OOM:

```yaml
args:
  - --mem-fraction-static
  - "0.80"  # Reduce from 0.85
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod -n dynamo <pod-name>

# Common issues:
# - Insufficient GPU resources
# - Image pull errors
# - Missing secrets
```

### Expert Load Imbalance

```bash
# Check EPLB logs
kubectl logs -n dynamo -l component=prefill | grep EPLB

# Adjust redundant experts
# Edit the deployment and increase --ep-num-redundant-experts
```

### Network Issues

```bash
# Verify InfiniBand
kubectl exec -n dynamo <pod-name> -- ibstat

# Check NIXL configuration
kubectl logs -n dynamo <pod-name> | grep nixl
```

## Cleanup

```bash
# Delete deployment
kubectl delete -f deepseek-r1-wideep.yaml

# Or delete by name
kubectl delete dynamographdeployment deepseek-r1-wideep -n dynamo
```

## Advanced: Using Helm

For production deployments, consider creating a Helm chart:

```bash
helm create deepseek-r1-chart
# Customize values.yaml with your configuration
helm install deepseek-r1 ./deepseek-r1-chart -n dynamo
```

## Resources

- [Dynamo Kubernetes Operator Docs](https://github.com/ai-dynamo/dynamo/tree/main/docs/kubernetes)
- [DynamoGraphDeployment API Reference](https://github.com/ai-dynamo/dynamo/blob/main/docs/kubernetes/api_reference.md)
- [Multi-node Deployment Examples](https://github.com/ai-dynamo/dynamo/tree/main/examples/deployments)


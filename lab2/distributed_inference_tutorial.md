# Distributed Inference with Dynamo

This interactive notebook guides you through deploying distributed inference with Dynamo on Kubernetes.

## Prerequisites

Before starting, ensure you have:
- ✅ Kubernetes cluster with GPU support
- ✅ `kubectl` and `helm` 3.x installed
- ✅ HuggingFace token from [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)

---


## Part 1: Single-Node-Sized Models with Aggregated Serving

Deploy multiple replicas of a model with KV cache-based routing for load balancing.

### Configuration

Set your configuration variables:



```python
import os

# Load environment variables from workshop-env.sh
# These are pre-configured based on your UID to prevent port conflicts
USER_JUPYTER_PORT = os.environ.get('USER_JUPYTER_PORT', '8888')
USER_FRONTEND_PORT = os.environ.get('USER_FRONTEND_PORT', '10000')
USER_FRONTEND2_PORT = os.environ.get('USER_FRONTEND2_PORT', '11000')
NAMESPACE = os.environ.get('NAMESPACE', f"dynamo-{os.environ.get('USER', 'unknown')}")

# Set workshop configuration
os.environ['RELEASE_VERSION'] = '0.5.0'
os.environ['NAMESPACE'] = NAMESPACE
os.environ['HF_TOKEN'] = 'your_huggingface_token'  # Replace with your HuggingFace token
os.environ['CACHE_PATH'] = '/data/huggingface-cache'  # Shared cache path

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎓 Lab 2: Distributed Inference Configuration")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"  User:                 {os.environ.get('USER')}")
print(f"  Release Version:      {os.environ['RELEASE_VERSION']}")
print(f"  Namespace:            {NAMESPACE}")
print(f"  Cache Path:           {os.environ['CACHE_PATH']}")
print("")
print("📌 Your Assigned Ports:")
print(f"  Aggregated Frontend:  {USER_FRONTEND_PORT}")
print(f"  Disaggregated Frontend: {USER_FRONTEND2_PORT}")
print("")
print("💡 Use localhost:{port} in your browser (via SSH tunnel)")
print(f"   - Aggregated:      localhost:10000")
print(f"   - Disaggregated:   localhost:11000")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

```

### Step 1: Install Dynamo CRDs

**Note:** CRDs are cluster-wide resources and only need to be installed **once per cluster**. If already installed, skip to Step 2.



```bash
%%bash
# Check if CRDs already exist
if kubectl get crd dynamographdeployments.nvidia.com &>/dev/null && \
   kubectl get crd dynamocomponentdeployments.nvidia.com &>/dev/null; then
    echo "✓ CRDs already installed, skipping to Step 2"
else
    echo "Installing Dynamo CRDs..."
    helm fetch https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-crds-$RELEASE_VERSION.tgz
    helm install dynamo-crds dynamo-crds-$RELEASE_VERSION.tgz --namespace default

    echo ""
    echo "Verifying CRD installation:"
    kubectl get crd | grep nvidia.com
fi

```

### Step 2: Install Dynamo Platform

This installs ETCD, NATS, and the Dynamo Operator Controller in your namespace.



```bash
%%bash
# Create namespace
kubectl create namespace $NAMESPACE 2>/dev/null || echo "Namespace $NAMESPACE already exists"

# Download platform chart
helm fetch https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-platform-$RELEASE_VERSION.tgz

# Install or upgrade
if helm list -n $NAMESPACE | grep -q dynamo-platform; then
    echo "Upgrading Dynamo platform..."
    helm upgrade dynamo-platform dynamo-platform-$RELEASE_VERSION.tgz --namespace $NAMESPACE
else
    echo "Installing Dynamo platform..."
    helm install dynamo-platform dynamo-platform-$RELEASE_VERSION.tgz --namespace $NAMESPACE
fi

echo ""
echo "Platform installation initiated. Checking status..."
kubectl get pods -n $NAMESPACE

```

### Step 3: Configure and Deploy Model

**⚠️ IMPORTANT:** Before deploying, we need to update the YAML configuration files with your specific values.



```bash
%%bash
# Update agg_router.yaml with your configuration

# Replace my-tag with actual version
sed -i "s/my-tag/$RELEASE_VERSION/g" agg_router.yaml

# Replace cache path
sed -i "s|/YOUR/LOCAL/CACHE/FOLDER|$CACHE_PATH|g" agg_router.yaml

echo "✓ Configuration updated in agg_router.yaml"
echo ""
echo "Verify image tags (should show version, not my-tag):"
grep "image:" agg_router.yaml

```

Create HuggingFace secret and deploy:



```bash
%%bash
# Create HuggingFace token secret
kubectl create secret generic hf-token-secret \
    --from-literal=HF_TOKEN=$HF_TOKEN \
    --namespace $NAMESPACE 2>/dev/null || echo "Secret already exists"

# Deploy the model
kubectl apply -f agg_router.yaml --namespace $NAMESPACE

echo ""
echo "✓ Deployment created. This will take 4-6 minutes for first run."
echo "  - Pulling container images"
echo "  - Downloading model from HuggingFace"
echo "  - Loading model and running torch.compile"

```

Monitor deployment progress:



```bash
%%bash
# Check deployment status
kubectl get dynamographdeployment -n $NAMESPACE

echo ""
echo "Pod status (wait for all pods to be 1/1 Ready):"
kubectl get pods -n $NAMESPACE | grep vllm

# To watch in real-time, uncomment the line below:
# kubectl get pods -n $NAMESPACE -w

```

### Step 4: Test the Deployment

Once all pods are `1/1 Ready`, forward the service port (run this in a separate terminal or background):



```bash
%%bash --bg
# Forward the service port (run in background with &)
kubectl port-forward deployment/vllm-agg-router-frontend $USER_FRONTEND_PORT:8000 -n $NAMESPACE &

echo "✓ Port forward started on localhost:${USER_FRONTEND_PORT}"
echo "  (To stop: use 'pkill -f port-forward' or press Ctrl+C in the terminal running it)"
sleep 5  # Give it time to start

```

#### Test 1: Simple Non-Streaming Request



```python
!curl localhost:${USER_FRONTEND_PORT}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{ \
    "model": "Qwen/Qwen2.5-1.5B-Instruct",\
    "messages": [{"role": "user", "content": "Hello! How are you?"}], \
    "stream": false,\
    "max_tokens": 50 \
  }'

```

#### Test 2: Streaming Request



```python
!curl localhost:${USER_FRONTEND_PORT}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{ \
    "model": "Qwen/Qwen2.5-1.5B-Instruct", \
    "messages": [{"role": "user", "content": "Write a short poem about AI"}], \
    "stream": true, \
    "max_tokens": 100 \
  }'

```

### Step 5 Delete the deployment


```python
!kubectl delete dynamographdeployment/vllm-agg-router -n $NAMESPACE
```

---

## Part 2: Deploy with AIConfigurator

AIConfigurator helps find optimal configurations for disaggregated serving by analyzing your model and hardware.

### Step 1: Install AIConfigurator



```python
# pre-installed in the container
# !pip3 install aiconfigurator

```

### Step 2: Run Configuration Analysis

Example: Find optimal configuration for Llama 3.1-70B on 16 H200 GPUs with TensorRT-LLM engine.



```python
!aiconfigurator cli default --model LLAMA3.1_70B --total_gpus 16 --system h200_sxm

```

### Step 3: Deploy with Recommended Settings

Use the AIConfigurator output as a reference for vLLM engine and update and deploy `disagg_router.yaml`:
In this workshop we use a smaller model and stick to TP=1 for one prefill worker and one decode worker. You can test with `meta-llama/Llama-3.1-70B-Instruct` with TP=2 with 4 GPU in total.


```bash
%%bash
# Update disagg_router.yaml
sed -i "s/my-tag/$RELEASE_VERSION/g" disagg_router.yaml
sed -i "s|/YOUR/LOCAL/CACHE/FOLDER|$CACHE_PATH|g" disagg_router.yaml

echo "✓ Configuration updated"
grep "image:" disagg_router.yaml

# Deploy
kubectl apply -f disagg_router.yaml --namespace $NAMESPACE

```

### Step 4: Forward port and test the endpoint


```bash
%%bash --bg
# Forward the service port (run in background with &)
kubectl port-forward deployment/vllm-v1-disagg-router-frontend $USER_FRONTEND2_PORT:8000 -n $NAMESPACE &

echo "✓ Port forward started on localhost:${USER_FRONTEND2_PORT}"
echo "  (To stop: use 'pkill -f port-forward' or press Ctrl+C in the terminal running it)"
sleep 5  # Give it time to start

```


```python
!curl localhost:${USER_FRONTEND2_PORT}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{ \
    "model": "Qwen/Qwen2.5-1.5B-Instruct",\
    "messages": [{"role": "user", "content": "Hello! Can you tell me a joke?"}], \
    "stream": false,\
    "max_tokens": 50 \
  }'
```

### Step 5 Delete the deployment


```python
!kubectl delete dynamographdeployment/vllm-v1-disagg-router -n $NAMESPACE
```

---

## Troubleshooting

### Check if pods are stuck in ImagePullBackOff



```bash
%%bash
# Check for image pull errors
POD=$(kubectl get pods -n $NAMESPACE | grep vllm | grep -v Running | head -1 | awk '{print $1}')

if [ -n "$POD" ]; then
    echo "Checking pod: $POD"
    kubectl describe pod $POD -n $NAMESPACE | grep -A 5 "Failed"
else
    echo "✓ All pods are running successfully"
fi

```

### View logs from a worker pod



```bash
%%bash
# Get logs from first worker pod
WORKER_POD=$(kubectl get pods -n $NAMESPACE | grep vllmdecodeworker | head -1 | awk '{print $1}')

if [ -n "$WORKER_POD" ]; then
    echo "Viewing logs from: $WORKER_POD"
    echo "Look for:"
    echo "  - 'Loading model weights...' (downloading)"
    echo "  - 'Model loading took X.XX GiB' (loaded)"
    echo "  - 'torch.compile takes X.X s' (ready)"
    echo ""
    kubectl logs $WORKER_POD -n $NAMESPACE --tail=50
else
    echo "No worker pods found yet"
fi

```

---

## Cleanup

To remove the deployment when done:



```bash
%%bash
# Delete deployment
kubectl delete dynamographdeployment vllm-agg-router -n $NAMESPACE
kubectl delete dynamographdeployment vllm-v1-disagg-router -n $NAMESPACE
kubectl delete secret hf-token-secret -n $NAMESPACE

# (Optional) Uninstall platform
# helm uninstall dynamo-platform -n $NAMESPACE

# (Optional) Delete namespace
# kubectl delete namespace $NAMESPACE

echo "✓ Cleanup complete"

```

---

## Additional Resources

- 📖 [Dynamo Documentation](https://docs.dynamo.nvidia.com)
- 🔧 [AIPerf Benchmarking Tool](https://github.com/ai-dynamo/aiperf)
- 📦 [NGC Container Catalog](https://catalog.ngc.nvidia.com/orgs/nvidia/teams/ai-dynamo/containers/vllm-runtime)
- 🎯 [vLLM Backend Guide](../../../components/backends/vllm/deploy/README.md)

---

**Congratulations! 🎉** You've successfully deployed Dynamo distributed inference on Kubernetes!


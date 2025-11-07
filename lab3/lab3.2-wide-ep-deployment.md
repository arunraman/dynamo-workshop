# Lab 3.2: Wide EP Production Deployment

## 🎯 Overview

Welcome to Lab 3.2! Now that you understand Expert Parallelism concepts from Lab 3.1, you'll **deploy a real MoE model** (DeepSeek-R1) using Wide EP in a production Kubernetes environment.

**What you'll do in this lab:**
1. ✅ Verify your environment is ready
2. 🔧 Build a custom Docker image with DeepEP support
3. 🚀 Deploy DeepSeek-R1 with Wide Expert Parallelism
4. 📊 Monitor expert load balancing (EPLB) in action
5. 🎯 Benchmark and optimize performance

**Time Required**: 90-120 minutes (includes Docker image build)

**Hardware Requirements**:
- 16 GPUs minimum (2 nodes × 8 GPUs each)
- High-bandwidth interconnect (NVLink or InfiniBand recommended)

---

## ⚠️ Before You Start

**Prerequisites (must be completed first):**
- ✅ Lab 3.1: Expert Parallelism Foundations
- ✅ Kubernetes cluster with GPU nodes
- ✅ **Dynamo Operator already installed** (from Lab 1 or Lab 2)
- ✅ kubectl configured and working
- ✅ HuggingFace account with access token

💡 **Note**: This lab assumes you've completed Lab 1 or Lab 2, where you installed the Dynamo Operator. We'll skip the operator installation and focus on deploying the MoE model.

---

## 📋 Table of Contents

**Part 1: Setup & Prerequisites**
- [Quick Recap: Lab 3.1 Concepts](#Quick-Recap:-Lab-3.1-Concepts)
- [Prerequisites Check](#Prerequisites-Check)

**Part 2: Deployment**
- [Understanding Your Deployment Options](#Understanding-Your-Deployment-Options)
- [Step-by-Step Deployment Guide](#Step-by-Step-Deployment-Guide)

**Part 3: Configuration Deep Dive**
- [SGLang Configuration Details](#Section-3:-Deploying-MoE-Models-with-SGLang-and-Expert-Parallelism)
- [Monitoring Expert Parallelism and EPLB](#Monitoring-Expert-Parallelism-and-EPLB)

**Part 4: Performance**
- [Benchmarking Your Deployment](#Section-4:-Performance-Benchmarking-for-EP-Deployments)

**Wrap-Up**
- [Summary](#Summary)

---

## 🔄 Quick Recap: Lab 3.1 Concepts

In Lab 3.1, you learned the foundations of Expert Parallelism. Here's a quick refresher:

**Key Concepts**:
- **MoE Models**: Only activate a subset of experts per token (e.g., 8 out of 256 experts)
- **Expert Parallelism (EP)**: Distribute experts across GPUs to scale capacity
- **Wide EP**: Spread experts across many nodes for maximum throughput
- **EPLB**: Dynamic load balancing to prevent GPU hotspots

**What you're deploying today:**
```
DeepSeek-R1 Model:
  - 671B total parameters
  - 256 experts (distributed via EP)
  - Only 8 experts active per token (~37B active params)
  - Disaggregated: Separate prefill & decode workers
```

**Deployment Architecture** (what we're building):
```
                ┌─────────────┐
                │  Frontend   │
                │  (CPU)      │
                └──────┬──────┘
                       │
           ┌───────────┴───────────┐
           │                       │
    ┌──────▼────────┐       ┌──────▼────────┐
    │ Prefill Worker│       │ Decode Worker │
    │   Node 1      │       │   Node 2      │
    │   8 GPUs      │──────▶│   8 GPUs      │
    │               │ NIXL  │               │
    │  TP=8, EP=8   │  KV   │ TP=8, DP=8    │
    │               │       │ EP=8          │
    └───────────────┘       └───────────────┘
```

Now let's verify your environment and deploy!

---

## ✅ Prerequisites Check

Before we start deploying, let's verify your environment is ready. Run the following checks:

---

### Environment Setup

First, load your user-specific configuration to ensure you use the correct ports:



```python
import os

# Load environment variables from workshop-env.sh
# These are pre-configured based on your UID to prevent port conflicts
USER_FRONTEND_PORT = os.environ.get('USER_FRONTEND_PORT', '10000')
NAMESPACE = os.environ.get('NAMESPACE', f"dynamo-{os.environ.get('USER', 'unknown')}")

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎓 Lab 3.2: Wide EP Deployment Configuration")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print(f"  User:             {os.environ.get('USER')}")
print(f"  Namespace:        {NAMESPACE}")
print(f"  Frontend Port:    {USER_FRONTEND_PORT}")
print("")
print("💡 Use localhost:10000 in your browser (via SSH tunnel)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

```

---

### Check 1: Verify Kubernetes Access

Make sure you can access your Kubernetes cluster and see your GPU nodes.


### Check 2: Verify GPU Availability

Check that you have at least 16 GPUs available across your nodes:



```bash
%%bash
# Check Kubernetes access and nodes
echo "=== Kubernetes Cluster Info ==="
kubectl cluster-info

echo -e "\n=== GPU Nodes ==="
kubectl get nodes -o custom-columns=NAME:.metadata.name,GPUs:.status.allocatable.'nvidia\.com/gpu'

echo -e "\n✅ If you see your nodes with GPUs listed above, you're good to go!"
```

### Check 3: Verify Dynamo Operator is Installed

Since you completed Lab 1 or Lab 2, the Dynamo Operator should already be installed. Let's verify:



```bash
%%bash
export NAMESPACE="dynamo-workshop"

echo "=== Checking Dynamo CRDs ==="
kubectl get crd | grep dynamo || echo "⚠️  No Dynamo CRDs found!"

echo -e "\n=== Checking Dynamo Operator Pod ==="
kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=dynamo-operator || echo "⚠️  Dynamo operator not found!"

echo -e "\n=== Checking Platform Components ==="
kubectl get pods -n ${NAMESPACE}

echo -e "\n✅ If you see dynamo-operator, etcd, and nats pods Running above, you're ready!"
echo "⚠️  If not, please complete Lab 1 or Lab 2 first to install the Dynamo Operator."
```

#### Step 3: Create Namespace and Install Dynamo Platform

Create the workshop namespace and install the Dynamo platform components (operator, etcd, NATS).



```bash
%%bash
export NAMESPACE="dynamo-workshop"

# Create namespace
# kubectl create namespace ${NAMESPACE}

# Fetch and install Dynamo platform
# helm fetch https://helm.ngc.nvidia.com/nvidia/ai-dynamo/charts/dynamo-platform-0.6.0.tgz
# helm install dynamo-platform dynamo-platform-0.6.0.tgz --namespace ${NAMESPACE} --set dynamo-operator.namespaceRestriction.enabled=true

# Wait for platform pods to be ready
echo "Waiting for platform pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=dynamo-platform -n ${NAMESPACE} --timeout=300s
```

#### Step 4: Verify Platform Installation

Check that all Dynamo platform components are running correctly.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

# Check all pods in the namespace
kubectl get pods -n ${NAMESPACE}

# Expected output: dynamo-operator, etcd, and nats pods should be Running
```




#### Step 5: Create HuggingFace Token Secret

Create a Kubernetes secret with your HuggingFace token for model downloads. Replace `your_hf_token_here` with your actual token from https://huggingface.co/settings/tokens



```bash
%%bash
export NAMESPACE="dynamo-workshop"

# Create HuggingFace token secret
# Replace 'your_hf_token_here' with your actual HF token
kubectl create secret generic hf-token-secret \
  --from-literal=HF_TOKEN='your_hf_token_here' \
  -n ${NAMESPACE}

# Verify secret was created
kubectl get secret hf-token-secret -n ${NAMESPACE}
```

#### Step 5.5: Build Custom Docker Image

The deployment requires a custom Docker image that includes DeepEP support for Wide EP functionality.

**Build the image**:
```bash
cd /mnt/raid/dynamo-workshop/dynamo
git checkout v0.6.0
docker build -f container/Dockerfile.sglang-wideep -t dynamo-wideep:0.6.0 .
```

This uses the official Dockerfile from the Dynamo repository and typically takes 30-60 minutes.

**For multi-node deployments**, push to your container registry:
```bash
docker tag dynamo-wideep:0.6.0 <your-registry>/dynamo-wideep:0.6.0
docker push <your-registry>/dynamo-wideep:0.6.0
```

After building and pushing, update the manifests with your registry in the next cell.

See the [official recipe](https://github.com/ai-dynamo/dynamo/tree/main/recipes/deepseek-r1/sglang-wideep) for more details.



```bash
%%bash
# Update manifests with your container registry
# Replace <your-registry> with your actual registry (e.g., docker.io/username, gcr.io/project)

cd /mnt/raid/dynamo-workshop/lab3

# Update both manifests
sed -i 's|<your-registry>/dynamo-wideep:0.6.0|your-actual-registry/dynamo-wideep:0.6.0|g' k8s/deepseek-r1-8gpu-singlenode.yaml
sed -i 's|<your-registry>/dynamo-wideep:0.6.0|your-actual-registry/dynamo-wideep:0.6.0|g' k8s/deepseek-r1-16gpu-multinode.yaml

echo "✅ Manifests updated with registry: your-actual-registry"

```





```bash
%%bash
echo "=== Available Storage Classes ==="
kubectl get storageclass

echo ""
echo "=== Storage Class Details (check for ReadWriteMany support) ==="
kubectl get storageclass -o custom-columns=NAME:.metadata.name,PROVISIONER:.provisioner,RECLAIM:.reclaimPolicy,VOLUMEBINDING:.volumeBindingMode

echo ""
echo "💡 Look for storage classes that support ReadWriteMany (RWX) access mode"
echo "   Common RWX provisioners: nfs, efs.csi.aws.com, file.csi.azure.com, filestore.csi.storage.gke.io"
echo ""
echo "📝 If you need to specify a storage class, edit k8s/model-cache-pvc.yaml"
echo "   Uncomment and set: storageClassName: <your-rwx-storage-class>"

```

#### Step 5.6: Create Model Cache PVC (Optional but Recommended)

To avoid downloading the model multiple times and speed up deployments, create a Persistent Volume Claim (PVC) to cache the model.

**Benefits**:
- ✅ Download model once, reuse across deployments
- ✅ Faster pod startup times (no HuggingFace download)
- ✅ Reduced network bandwidth usage
- ✅ Consistent model versions across workers

**Storage Requirements**: ~500GB for DeepSeek-R1 (671B parameters)

**Important**: First check your cluster's available storage classes and update `k8s/model-cache-pvc.yaml` if needed.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

echo "=== Creating Model Cache PVC ==="
kubectl apply -f k8s/model-cache-pvc.yaml

echo ""
echo "=== Waiting for PVC to be bound ==="
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/model-cache-pvc -n ${NAMESPACE} --timeout=300s

echo ""
echo "✅ PVC created and bound!"
kubectl get pvc model-cache-pvc -n ${NAMESPACE}

```

#### Step 5.7: Download Model to Cache (One-Time Setup)

Run a Kubernetes Job to download the DeepSeek-R1 model to the PVC. This is a one-time operation that may take 15-30 minutes depending on your network speed.

**What this does**:
1. Creates a temporary pod with the model cache PVC mounted
2. Downloads the full DeepSeek-R1 model from HuggingFace (~100GB)
3. Stores it in `/model-cache/deepseek-r1` on the PVC
4. Exits when complete

**Note**: You can monitor progress with `kubectl logs -f job/deepseek-r1-model-download -n dynamo-workshop`



```bash
%%bash
export NAMESPACE="dynamo-workshop"

echo "=== Starting Model Download Job ==="
kubectl apply -f k8s/model-download-job.yaml

echo ""
echo "📥 Model download started. This may take 15-30 minutes..."
echo ""
echo "Monitor progress with:"
echo "  kubectl logs -f job/deepseek-r1-model-download -n ${NAMESPACE}"
echo ""
echo "Check job status:"
kubectl get job deepseek-r1-model-download -n ${NAMESPACE}

echo ""
echo "💡 The job will download ~100GB. You can proceed to the next steps once complete."
echo "   To wait for completion, run:"
echo "   kubectl wait --for=condition=complete job/deepseek-r1-model-download -n ${NAMESPACE} --timeout=3600s"

```

#### Step 5.8: Verify Model Download (Optional)

Check that the model was successfully downloaded to the PVC.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

echo "=== Checking Model Download Job Status ==="
kubectl get job deepseek-r1-model-download -n ${NAMESPACE}

echo ""
echo "=== Job Logs (last 20 lines) ==="
kubectl logs job/deepseek-r1-model-download -n ${NAMESPACE} --tail=20 || echo "Job not started yet or no logs available"

echo ""
echo "💡 Once the job shows 'Completions: 1/1', the model is ready!"
echo "   You can then proceed to deploy DeepSeek-R1 using the cached model."

```

#### Step 5.9: Clean Up Download Job (After Completion)

Once the model download is complete (job shows `Completions: 1/1`), you can safely delete the download job. The downloaded model remains on the PVC.

**Why clean up?**
- Removes completed pods from the cluster
- Frees up cluster resources
- Keeps your namespace clean

**Note**: This does NOT delete the downloaded model - only the job pod.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

echo "=== Checking if download is complete ==="
JOB_STATUS=$(kubectl get job deepseek-r1-model-download -n ${NAMESPACE} -o jsonpath='{.status.succeeded}' 2>/dev/null)

if [ "$JOB_STATUS" = "1" ]; then
    echo "✅ Download job completed successfully!"
    echo ""
    echo "=== Deleting download job ==="
    kubectl delete job deepseek-r1-model-download -n ${NAMESPACE}
    echo ""
    echo "✅ Job deleted. Model is safely stored on the PVC."
else
    echo "⚠️  Download job is not complete yet."
    echo ""
    echo "Current status:"
    kubectl get job deepseek-r1-model-download -n ${NAMESPACE}
    echo ""
    echo "💡 Wait for the job to complete before running this step."
    echo "   Monitor with: kubectl logs -f job/deepseek-r1-model-download -n ${NAMESPACE}"
fi

```

#### Step 6: Deploy DeepSeek-R1 with Wide EP

Deploy the DeepSeek-R1 model using the pre-configured Wide EP manifest. This will create a disaggregated deployment with prefill and decode workers.

**Model Loading**:
- ✅ **With Model Cache** (Steps 5.6-5.8 completed): Workers will load from `/model-cache/deepseek-r1` (fast startup, ~2-5 minutes)
- ⚠️ **Without Model Cache** (Steps 5.6-5.8 skipped): Workers will download from HuggingFace (slower startup, ~10-15 minutes per worker)

The manifest `deepseek-r1-8gpu-singlenode.yaml` is already configured to use the model cache if available.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

echo "🚀 Deploying DeepSeek-R1 with Wide Expert Parallelism..."
echo ""

# Deploy using Single-Node Workers configuration (recommended)
kubectl apply -f k8s/deepseek-r1-8gpu-singlenode.yaml -n ${NAMESPACE}

# For multi-node deployment (if you have 4 nodes × 4 GPUs), use:
# kubectl apply -f k8s/deepseek-r1-16gpu-multinode.yaml -n ${NAMESPACE}

echo ""
echo "✅ Deployment created!"
echo ""
echo "📊 Checking deployment status..."
kubectl get dynamographdeployment -n ${NAMESPACE}

echo ""
echo "💡 The pods will now start. This may take 5-10 minutes as:"
echo "   1. Model weights are downloaded from HuggingFace (~100GB)"
echo "   2. Workers initialize and load the model into GPU memory"
echo "   3. Expert Parallelism topology is established"
```

#### Step 7: Monitor Deployment Progress

Watch the pods as they start up. This may take several minutes as the model is downloaded and loaded. Press Ctrl+C to stop watching.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

# Watch pods being created and starting
# Press Ctrl+C to stop watching
kubectl get pods -n ${NAMESPACE} -w
```

#### Step 8: Check Pod Logs (Optional)

If you encounter issues, check the logs of the pods to see what's happening.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

# Check logs of prefill workers
kubectl logs -n ${NAMESPACE} -l component=prefill --tail=50

# Check logs of decode workers
kubectl logs -n ${NAMESPACE} -l component=decode --tail=50

# Check frontend logs
kubectl logs -n ${NAMESPACE} -l component=frontend --tail=50

```

#### Step 9: Port Forward to Access the Frontend

Create a port forward to access the deployment from your local machine. Keep this terminal running while testing.



```bash
%%bash
export NAMESPACE="dynamo-workshop"

# Port forward to access the frontend (run in background or separate terminal)
kubectl port-forward svc/deepseek-r1-wideep-frontend $USER_FRONTEND_PORT:8000 -n ${NAMESPACE}

```

#### Step 10: Test the Deployment with curl

Send a test request to verify the deployment is working. Make sure the port-forward from the previous step is still running.



```bash
%%bash
# Test the deployment with a simple request
curl http://localhost:${USER_FRONTEND_PORT}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-ai/DeepSeek-R1",
    "messages": [{"role": "user", "content": "Explain MoE models in one sentence"}],
    "max_tokens": 100
  }'

```

#### ✅ Deployment Complete!

If the curl command above returned a response, your Wide EP deployment is working!

**Next Steps:**
- Continue to Section 3 to learn about SGLang configuration details
- Try the benchmarking exercises in Section 4
- Explore the configuration files in `k8s/` directory

**To clean up when done:**
```bash
# For single-node deployment
kubectl delete -f k8s/deepseek-r1-8gpu-singlenode.yaml -n ${NAMESPACE}

# For multi-node deployment
# kubectl delete -f k8s/deepseek-r1-16gpu-multinode.yaml -n ${NAMESPACE}
```

---



```bash
%%bash
export NAMESPACE="dynamo-workshop"
kubectl delete -f k8s/deepseek-r1-8gpu-singlenode.yaml -n ${NAMESPACE}

```

## Section 3: Deploying MoE Models with SGLang and Expert Parallelism

Now that you understand how to deploy with Kubernetes, let's dive deeper into hands-on deployment of MoE models with Expert Parallelism using Dynamo's **SGLang backend**.

**In this section, you'll learn:**
- How to configure SGLang for Expert Parallelism
- Single-node vs multi-node deployment strategies
- EPLB configuration and tuning
- Monitoring and troubleshooting EP deployments

### Prerequisites for MoE Deployment

**What you need**:
- Multiple GPUs (minimum 4 GPUs for this example)
- NATS and etcd running (infrastructure from Lab 2)
- Model that fits with EP distribution
- High-bandwidth interconnect (InfiniBand or NVLink preferred)

**Check GPU availability**:


### SGLang Deployment Configurations

All SGLang configuration is done via command-line arguments in the Kubernetes manifests.

**Available Manifests** (based on official Dynamo recipes):
1. `k8s/deepseek-r1-8gpu-singlenode.yaml` - 8 GPUs (Example 1)
2. `k8s/deepseek-r1-16gpu-multinode.yaml` - 16 GPUs (Example 2)

Each manifest includes complete configuration for:
- Expert Parallelism parameters (`--tp-size`, `--dp-size`, `--ep-size`)
- EPLB settings (EP redundancy, load balancing)
- Memory optimization (`--mem-fraction-static`)
- Disaggregated prefill/decode workers with NIXL transfer

**Reference**: [Official Dynamo Recipes](https://github.com/ai-dynamo/dynamo/tree/main/recipes/deepseek-r1/sglang-wideep)



```python
# List available Kubernetes manifests
from pathlib import Path

print("=" * 60)
print("Lab 3 DeepSeek-R1 Deployment Manifests")
print("=" * 60)

k8s_dir = Path("k8s")
if k8s_dir.exists():
    manifests = [
        ("deepseek-r1-8gpu-singlenode.yaml", "Example 1: 8 GPUs (Single-Node)"),
        ("deepseek-r1-16gpu-multinode.yaml", "Example 2: 16 GPUs (Multi-Node)"),
        ("README.md", "Kubernetes Deployment Guide")
    ]

    print("\nAvailable Manifests:")
    print("-" * 60)
    for filename, description in manifests:
        file = k8s_dir / filename
        if file.exists():
            if filename.endswith('.yaml'):
                size = file.stat().st_size
                print(f"  ✓ {filename:<40} ({size:>6,} bytes)")
                print(f"    {description}")
            else:
                print(f"  ✓ {filename:<40} {description}")
else:
    print("  ⚠️  k8s/ directory not found")

print("\n📝 Based on official Dynamo recipes:")
print("   https://github.com/ai-dynamo/dynamo/tree/main/recipes/deepseek-r1/sglang-wideep")
print("=" * 60)

```

### Example 1: Single-Node Workers (Recommended for 2 Nodes × 8 GPUs)

**✅ Use this configuration for your setup!** (2 nodes × 8 GPUs each = 16 GPUs total)

This deploys DeepSeek-R1 with disaggregated prefill/decode workers, each worker running on a single node.

**Manifest**: `k8s/deepseek-r1-8gpu-singlenode.yaml`

**Architecture**:
```
                ┌─────────────┐
                │  Frontend   │
                │  (CPU only) │
                └──────┬──────┘
                       │
           ┌───────────┴───────────┐
           │                       │
    ┌──────▼────────┐       ┌──────▼────────┐
    │ Prefill Worker│       │ Decode Worker │
    │   Node 1      │       │   Node 2      │
    │   8 GPUs      │──────▶│   8 GPUs      │
    │               │ NIXL  │               │
    │  TP=8, EP=8   │  KV   │ TP=8, DP=8    │
    │               │       │ EP=8, DP-Attn │
    └───────────────┘       └───────────────┘
```

**Configuration Details**:

**Total Resources**: 16 GPUs across 2 nodes

**Prefill Worker** (1 pod, 8 GPUs on Node 1):
- TP=8: Model tensor parallelism across 8 GPUs (NVLink within node)
- EP=8: 256 experts distributed across 8 GPUs
- Processes prompt encoding
- Transfers KV cache to decode via NIXL

**Decode Worker** (1 pod, 8 GPUs on Node 2):
- TP=8: Model tensor parallelism across 8 GPUs (NVLink within node)
- DP=8: Data parallelism for batch processing
- EP=8: Expert parallelism (256 experts distributed)
- DP Attention: Parallel attention computation
- Receives KV cache from prefill
- Generates tokens autoregressively

**Key Parameters**:
```bash
# Prefill Worker (Node 1)
--model-path deepseek-ai/DeepSeek-R1
--tp-size 8
--ep-size 8
--disaggregation-mode prefill
--disaggregation-transfer-backend nixl

# Decode Worker (Node 2)
--model-path deepseek-ai/DeepSeek-R1
--tp-size 8
--dp-size 8
--ep-size 8
--enable-dp-attention
--disaggregation-mode decode
--disaggregation-transfer-backend nixl
```

**Why this configuration?**
- ✅ **Perfect for 2 nodes × 8 GPUs** (your hardware!)
- ✅ Each worker stays on one node - fast NVLink communication
- ✅ No cross-node TP overhead - better performance
- ✅ Simpler to deploy and debug
- ✅ Optimal for learning Wide EP concepts


### Example 2: Multi-Node Workers (For Larger Clusters)

**Note**: This configuration is for clusters with **4+ nodes** and demonstrates advanced multi-node deployment patterns.

**Your Setup**: You have **2 nodes × 8 GPUs = 16 GPUs**. Use **Example 1** (`deepseek-r1-8gpu-singlenode.yaml`).

**Manifest**: `k8s/deepseek-r1-16gpu-multinode.yaml` (requires 4 nodes × 4 GPUs)

**Architecture** (for 4-node clusters):
```
                ┌─────────────┐
                │  Frontend   │
                │  (CPU only) │
                └──────┬──────┘
                       │
           ┌───────────┴─────────────┐
           │                         │
    ┌──────▼────────────┐     ┌──────▼───────────┐
    │ Prefill Worker    │     │ Decode Worker    │
    │  (Multi-node)     │     │  (Multi-node)    │
    │                   │     │                  │
    │ ┌────────────┐    │     │ ┌────────────┐   │
    │ │Node 1      │    │────▶│ │Node 3      │   │
    │ │4 GPUs      │    │NIXL │ │4 GPUs      │   │
    │ └────────────┘    │ KV  │ └────────────┘   │
    │ ┌────────────┐    │     │ ┌────────────┐   │
    │ │Node 2      │    │     │ │Node 4      │   │
    │ │4 GPUs      │    │     │ │4 GPUs      │   │
    │ └────────────┘    │     │ └────────────┘   │
    │                   │     │                  │
    │ Total: 8 GPUs     │     │ Total: 8 GPUs    │
    │ TP=8, EP=8        │     │ TP=8, DP=8, EP=8 │
    └───────────────────┘     └──────────────────┘
```

**Configuration Details**:

**Total Resources**: 16 GPUs across **4 nodes** (4 GPUs per node)

**Prefill Worker** (2 pods × 4 GPUs = 8 GPUs):
- Multi-node: 2 pods across 2 nodes (Node 1 + Node 2)
- TP=8: Model sharded across 8 GPUs (cross-node via NCCL)
- EP=8: 256 experts distributed across 8 GPUs
- Requires InfiniBand/RDMA for efficient cross-node communication

**Decode Worker** (2 pods × 4 GPUs = 8 GPUs):
- Multi-node: 2 pods across 2 nodes (Node 3 + Node 4)
- TP=8: Model sharded across 8 GPUs (cross-node via NCCL)
- DP=8: Data parallelism for batch processing
- EP=8: Expert parallelism

**When to use this**:
- ⚠️ **You need 4 nodes** with 4 GPUs each (not 2 nodes with 8 GPUs each)
- Shows advanced multi-node coordination
- Demonstrates cross-node TP/EP communication
- Requires excellent inter-node networking (25+ Gbps InfiniBand)

**For your 2-node × 8 GPU setup**: Use Example 1 instead!



```python
# DeepSeek-R1 Deployment Examples
# Choose the right configuration for your hardware

print("""
=================================================================
DeepSeek-R1 Wide EP Deployment Commands
=================================================================

Example 1: Single-Node Workers (✅ USE THIS for 2 nodes × 8 GPUs)
───────────────────────────────────────────────────────────────
Manifest: k8s/deepseek-r1-8gpu-singlenode.yaml
Deploy:   kubectl apply -f k8s/deepseek-r1-8gpu-singlenode.yaml

Hardware: 2 nodes × 8 GPUs each = 16 GPUs total
Architecture:
  - Prefill: 1 pod × 8 GPUs on Node 1 (TP=8, EP=8)
  - Decode:  1 pod × 8 GPUs on Node 2 (TP=8, DP=8, EP=8)
  - Fast NVLink within each node, no cross-node TP overhead


Example 2: Multi-Node Workers (⚠️  Requires 4 nodes × 4 GPUs)
───────────────────────────────────────────────────────────────
Manifest: k8s/deepseek-r1-16gpu-multinode.yaml
Deploy:   kubectl apply -f k8s/deepseek-r1-16gpu-multinode.yaml

Hardware: 4 nodes × 4 GPUs each = 16 GPUs total (DIFFERENT from above!)
Architecture:
  - Prefill: 2 pods × 4 GPUs each (TP=8 cross-node)
  - Decode:  2 pods × 4 GPUs each (TP=8 cross-node, DP=8, EP=8)
  - Requires excellent inter-node networking (InfiniBand/RDMA)
  - Only use if you have 4 nodes with 4 GPUs each


📝 For your 2-node × 8 GPU setup, use Example 1!

=================================================================
""")

```

### Monitoring Expert Parallelism and EPLB

When running MoE models with EP and EPLB, monitoring is crucial to ensure optimal performance.

#### Key Metrics to Monitor

**1. Expert Usage Distribution**
```python
# SGLang automatically logs expert usage statistics
# Look for logs like:
# "Expert usage: [0.05, 0.12, 0.03, 0.15, ...]"
# These show the fraction of tokens routed to each expert
```

**2. GPU Utilization per Expert**
```bash
# Use nvidia-smi to check GPU utilization
watch -n 1 nvidia-smi

# For detailed metrics, use DCGM:
dcgmi dmon -e 155,156,203,204 -d 1
# 155 = GPU Utilization
# 156 = Memory Utilization
# 203 = Tensor Core Utilization
# 204 = FP16 Activity
```

**3. EPLB Rebalancing Events**
```python
# Enable verbose logging to see EPLB rebalancing
# Set environment variable: DYNAMO_LOG=debug

# Look for logs like:
# "EPLB: Rebalancing experts after 100 iterations"
# "EPLB: Expert 5 replicated to GPU 2 (high usage: 0.25)"
# "EPLB: Expert 17 removed from GPU 3 (low usage: 0.01)"
```

**4. Network Bandwidth (for Multi-Node)**
```bash
# Monitor InfiniBand bandwidth
ibstat

# Monitor network throughput
iftop -i ib0  # Replace ib0 with your IB interface
```

#### Troubleshooting Common Issues

**Issue 1: Uneven GPU Utilization**
```
Symptoms:
- Some GPUs at 100%, others at <50%
- Throughput lower than expected
- Long token generation times

Solution:
- Enable EPLB: --enable-eplb
- Increase redundant experts: --ep-num-redundant-experts 32
- Adjust rebalancing frequency: --eplb-rebalance-num-iterations 50
```

**Issue 2: High Memory Usage**
```
Symptoms:
- OOM errors
- Cannot create redundant experts

Solution:
- Reduce memory fraction: --mem-fraction-static 0.80 (from 0.85)
- Reduce redundant experts: --ep-num-redundant-experts 16
- Disable features: --disable-radix-cache
```

**Issue 3: Slow Expert All-to-All Communication**
```
Symptoms:
- High latency during expert routing
- Low GPU utilization despite balanced load

Solution:
- Use DeepEP backend: --moe-a2a-backend deepep
- Enable two-batch overlap: --enable-two-batch-overlap
- Check network: Ensure InfiniBand is active and configured
```

**Issue 4: EPLB Not Rebalancing**
```
Symptoms:
- No rebalancing logs
- Expert usage remains imbalanced over time

Solution:
- Enable explicit EPLB: --enable-eplb
- Use appropriate recorder mode: --expert-distribution-recorder-mode stat
- Lower rebalance threshold: --eplb-rebalance-num-iterations 50
```

#### Performance Tuning Tips

**1. Optimize Memory Allocation**
```bash
# Start with conservative memory fraction
--mem-fraction-static 0.80

# Gradually increase if no OOM
--mem-fraction-static 0.85

# Monitor with nvidia-smi
```

**2. Tune Redundant Expert Count**
```bash
# Formula: redundant_experts ≈ num_GPUs / 2 to num_GPUs
# For 32 GPUs: try 16-32 redundant experts

# Start low
--ep-num-redundant-experts 16

# Increase if imbalance persists
--ep-num-redundant-experts 32
```

**3. DeepEP Mode Selection**
```bash
# For prefill (focus on throughput)
--deepep-mode normal

# For decode (focus on latency)
--deepep-mode low_latency
```

**4. Batch Size Tuning**
```bash
# For decode, tune CUDA graph batch size
# Larger = better throughput, more memory
--cuda-graph-bs 128

# If OOM, reduce
--cuda-graph-bs 64
```


## Section 4: Performance Benchmarking for EP Deployments

Now that you've deployed Wide EP with SGLang, let's learn how to **measure and optimize performance**.

**In this section, you'll learn:**
- Key metrics for MoE model deployments
- How to benchmark Expert Parallelism and EPLB
- Comparing single-node vs multi-node performance
- Measuring expert load balancing effectiveness

### Objectives
- Benchmark Expert Parallelism and EPLB performance
- Compare single-node vs multi-node deployments
- Measure expert load balancing effectiveness
- Analyze throughput and latency characteristics

### Key Metrics for MoE Models

#### 1. **Throughput Metrics**
```python
# Requests per second across all replicas
# Tokens per second (both input and output)
# Expert activations per second
```

#### 2. **Latency Metrics**
```python
# Time to First Token (TTFT)
# Time per Output Token (TPOT)
# Expert routing latency
# All-to-all communication time
```

#### 3. **Load Balancing Metrics**
```python
# GPU utilization variance (should be low with EPLB)
# Expert usage distribution (should be balanced)
# EPLB rebalancing frequency
# Redundant expert utilization
```

#### 4. **Resource Utilization**
```python
# GPU memory usage per worker
# Network bandwidth (especially for multi-node)
# CPU usage for pre/post-processing
```

### Benchmarking Exercise 1: Expert Load Distribution

**Goal**: Measure how EPLB improves expert load balancing

**Setup**:
1. Deploy a MoE model WITHOUT EPLB
2. Run workload and measure GPU utilization variance
3. Enable EPLB and re-run same workload
4. Compare results



```python
import time
import requests
import statistics

def benchmark_deployment(endpoint, num_requests=10):
    """Benchmark an EP deployment"""
    print(f"Benchmarking {endpoint}...")
    print(f"Sending {num_requests} requests...\n")

    latencies = []

    for i in range(num_requests):
        start = time.time()
        try:
            response = requests.post(
                f"{endpoint}/v1/chat/completions",
                json={
                    "model": "deepseek-ai/DeepSeek-R1",
                    "messages": [{"role": "user", "content": "Hello"}],
                    "max_tokens": 50
                },
                timeout=30
            )
            latency = time.time() - start
            latencies.append(latency)
            print(f"Request {i+1}: {latency:.2f}s")
        except Exception as e:
            print(f"Request {i+1}: Failed - {e}")

    if latencies:
        print(f"\nResults:")
        print(f"  Mean latency: {statistics.mean(latencies):.2f}s")
        print(f"  Median latency: {statistics.median(latencies):.2f}s")
        print(f"  Throughput: {num_requests / sum(latencies):.2f} req/s")

# Example usage (uncomment when deployment is running):
# benchmark_deployment("http://localhost:8000", num_requests=10)

```

## Summary

### What You Learned
- ✅ Wide EP deployments across multiple nodes with SGLang
- ✅ Expert Parallelism configuration and EPLB tuning
- ✅ Advanced performance measurement and optimization
- ✅ Production deployment best practices with Kubernetes
- ✅ Building custom Docker images with DeepEP support

### Key Takeaways
- Wide EP enables datacenter-scale MoE deployments
- EPLB significantly improves load balancing and throughput
- Multi-node deployments require careful network and resource planning
- Custom Docker images are required for DeepEP backend support
- SGLang provides flexible deployment and easier experimentation

### Performance Improvements with Wide EP
Key benefits you can expect:
- **SGLang with DeepEP**: Optimized all-to-all communication for expert routing
- **EPLB**: Balanced GPU utilization, preventing hotspots
- **Multi-Node**: Horizontal scaling with proper network configuration
- **Wide EP**: Better resource utilization across large GPU clusters
- **Disaggregated Serving**: Separate prefill and decode workers for efficiency

### Next Steps
- Apply these techniques to your production deployments
- Experiment with different configurations for your specific workloads
- Contribute optimizations back to the Dynamo community
- Explore the latest features in the [Dynamo repository](https://github.com/ai-dynamo/dynamo)

---

## Congratulations!

You've completed the Dynamo Workshop. You now have the knowledge to:
- Deploy Dynamo from local to datacenter scale
- Choose the right topology for your use case
- Optimize performance with Wide EP and EPLB
- Operate production-grade LLM inference infrastructure


# Lab 1 Extension: Monitoring Dynamo with Prometheus and Grafana

## Overview

In this extension to Lab 1, you will:
- Install namespace-scoped Prometheus and Grafana using kube-prometheus-stack
- Configure metrics collection from your Dynamo deployment
- Create and view the Dynamo dashboard in Grafana
- Explore metrics in Prometheus
- Understand key performance metrics

**Prerequisites**: Complete Lab 1 (Introduction and Kubernetes-Based Deployment)

## Duration: ~30 minutes

---

## Section 1: Install Monitoring Stack (Namespace-Scoped)

### Objectives
- Install kube-prometheus-stack in your namespace
- Understand Prometheus Operator custom resources (PodMonitor, ServiceMonitor)
- Configure namespace-scoped monitoring

### Important: Namespace-Scoped Monitoring

Since we're using a **shared Kubernetes cluster**, we'll install the monitoring stack in your personal namespace. This ensures:
- Your monitoring doesn't interfere with others
- You have full control over your Grafana dashboards
- Resources are isolated and easy to clean up

### Architecture
```
Your Namespace:
  ├── Dynamo Deployment (Frontend + Workers)
  ├── Prometheus (scrapes metrics from Dynamo)
  ├── Grafana (visualizes metrics)
  └── PodMonitors (auto-discover Dynamo pods)
```

### Step 1: Verify Environment Variables

Ensure your environment is set up from Lab 1:


```
%%python
import os

# Verify environment variables from Lab 1
print("Current configuration:")
print(f"  Namespace: {os.environ.get('NAMESPACE', 'NOT SET - Run Lab 1 first!')}")
print(f"  Release Version: {os.environ.get('RELEASE_VERSION', 'NOT SET')}")

# Verify namespace is set
if not os.environ.get('NAMESPACE'):
    print("\n⚠️  WARNING: NAMESPACE not set. Please run Lab 1 first.")
else:
    print("\n✓ Environment ready for monitoring setup")
```

### Step 2: Add Prometheus Helm Repository


```bash
%%bash
# Add the Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "✓ Prometheus Helm repository added"
```

### Step 3: Install kube-prometheus-stack (Namespace-Scoped)

This installs Prometheus, Grafana, and the Prometheus Operator in your namespace:


```bash
%%bash
# Install kube-prometheus-stack in your namespace
echo "Installing kube-prometheus-stack in namespace: $NAMESPACE"
echo "This may take 3-5 minutes..."

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.podMonitorNamespaceSelector="{}" \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.serviceMonitorNamespaceSelector="{}" \
  --set grafana.adminPassword=admin

echo ""
echo "✓ Monitoring stack installation initiated"
```

### Step 4: Wait for Monitoring Stack to Be Ready

Re-run the following cell until all monitoring pods are Running:


```bash
%%bash
# Check monitoring stack pods
echo "Monitoring stack pods in namespace $NAMESPACE:"
kubectl get pods -n $NAMESPACE | grep -E "(prometheus|grafana|alertmanager|operator)"

echo ""
echo "Wait for all pods to show '1/1' or '2/2' in the READY column"
```

### Step 5: Verify Prometheus Operator


```bash
%%bash
# Verify the Prometheus Operator is running
kubectl get deployment -n $NAMESPACE | grep operator

echo ""
echo "✓ Prometheus Operator is managing metrics collection"
```

---

## Section 2: Configure Metrics Collection

### Objectives
- Understand PodMonitor resources
- Configure automatic metrics discovery
- Verify metrics are being scraped

### How Dynamo Exposes Metrics

Dynamo components expose metrics through:
- **Frontend**: Exposes `/metrics` on its HTTP port (8000)
  - Request rates, latencies, token metrics
- **Workers**: Exposes `/metrics` on system port
  - Worker-specific metrics, queue stats

### Step 1: Verify Dynamo Deployment Has Metrics Labels

The Dynamo operator automatically adds metrics labels to pods:


```bash
%%bash
# Check if your Dynamo pods have metrics labels
echo "Checking Dynamo pod labels:"
kubectl get pods -n $NAMESPACE -l nvidia.com/metrics-enabled=true --show-labels

echo ""
echo "Look for labels: nvidia.com/metrics-enabled=true"
```

### Step 2: Check if PodMonitors Were Created

The Dynamo operator should automatically create PodMonitor resources:


```bash
%%bash
# List PodMonitors in your namespace
echo "PodMonitors in namespace $NAMESPACE:"
kubectl get podmonitor -n $NAMESPACE

echo ""
echo "You should see PodMonitors for frontend and worker components"
```

### Step 3: Manually Test Metrics Endpoint

Let's verify metrics are accessible:


```bash
%%bash
# Get the frontend pod name
FRONTEND_POD=$(kubectl get pods -n $NAMESPACE | grep frontend | head -1 | awk '{print $1}')

if [ -n "$FRONTEND_POD" ]; then
    echo "Testing metrics endpoint from frontend pod: $FRONTEND_POD"
    echo ""
    kubectl exec -n $NAMESPACE $FRONTEND_POD -- curl -s localhost:8000/metrics | head -20
    echo ""
    echo "✓ Metrics endpoint is accessible"
else
    echo "⚠️  Frontend pod not found. Make sure your deployment from Lab 1 is running."
fi
```

### Step 4: Send Test Traffic to Generate Metrics

Let's generate some traffic to populate metrics:


```bash
%%bash --bg
# Ensure port-forward is running (in background)
kubectl port-forward deployment/vllm-agg-router-frontend $USER_FRONTEND_PORT:8000 -n $NAMESPACE &
sleep 5
echo "✓ Port forward running on localhost:${USER_FRONTEND_PORT}"
```

Send test requests:


```
%%python
!curl http://localhost:${USER_FRONTEND_PORT}/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{ \
    "model": "Qwen/Qwen2.5-1.5B-Instruct",\
    "messages": [{"role": "user", "content": "Hello! Tell me a short joke."}], \
    "stream": false,\
    "max_tokens": 50 \
  }'
```

Run a few more requests:


```
%%python
for i in range(5):
    !curl -s http://localhost:${USER_FRONTEND_PORT}/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d '{"model": "Qwen/Qwen2.5-1.5B-Instruct", "messages": [{"role": "user", "content": "Tell me about AI"}], "stream": false, "max_tokens": 30}' \
      > /dev/null

print("✓ Sent 5 test requests to generate metrics")
```

---

## Section 3: Deploy Grafana Dashboard

### Objectives
- Configure the Dynamo Grafana dashboard
- Load dashboard into Grafana
- Understand dashboard panels

### Step 1: Download Dynamo Dashboard ConfigMap

First, let's get the dashboard configuration from the Dynamo repository:


```bash
%%bash
# Navigate to the metrics directory
cd ../dynamo/deploy/metrics/k8s

# Check if the dashboard ConfigMap exists
if [ -f grafana-dynamo-dashboard-configmap.yaml ]; then
    echo "✓ Found Grafana dashboard ConfigMap"
    ls -lh grafana-dynamo-dashboard-configmap.yaml
else
    echo "⚠️  Dashboard ConfigMap not found"
    echo "Expected location: ../dynamo/deploy/metrics/k8s/"
fi
```

### Step 2: Apply Dashboard ConfigMap to Your Namespace


```bash
%%bash
# Apply the Dynamo dashboard to your namespace
kubectl apply -f ../dynamo/deploy/metrics/k8s/grafana-dynamo-dashboard-configmap.yaml -n $NAMESPACE

echo ""
echo "✓ Dynamo dashboard ConfigMap applied"
```

### Step 3: Verify Dashboard ConfigMap


```bash
%%bash
# Check if the ConfigMap was created
kubectl get configmap -n $NAMESPACE | grep dynamo-dashboard

echo ""
echo "✓ Dashboard ConfigMap is ready"
```

### Step 4: Restart Grafana to Load Dashboard

Grafana needs to be restarted to pick up the new dashboard:


```bash
%%bash
# Restart Grafana pod to load the new dashboard
echo "Restarting Grafana..."
kubectl delete pod -n $NAMESPACE -l app.kubernetes.io/name=grafana

echo ""
echo "Waiting for Grafana to restart..."
sleep 10
kubectl get pods -n $NAMESPACE | grep grafana

echo ""
echo "✓ Grafana restarted"
```

---

## Section 4: Access Prometheus and Grafana

### Objectives
- Access Prometheus UI
- Access Grafana UI
- Query metrics in Prometheus
- View Dynamo dashboard in Grafana

### Step 1: Port Forward Prometheus


```bash
%%bash --bg
# Forward Prometheus port (run in background)
kubectl port-forward svc/prometheus-kube-prometheus-prometheus $USER_PROMETHEUS_PORT:9090 -n $NAMESPACE &

echo "✓ Prometheus UI available at http://localhost:${USER_PROMETHEUS_PORT}"
echo "  (To stop: pkill -f 'port-forward.*9090')"
sleep 5
```

### Step 2: Explore Prometheus Metrics

Open http://localhost:${USER_PROMETHEUS_PORT} in your browser and try these queries:

**Example Prometheus Queries:**

1. **Total requests to frontend:**
   ```
   dynamo_frontend_requests_total
   ```

2. **Time to first token (95th percentile):**
   ```
   histogram_quantile(0.95, dynamo_frontend_time_to_first_token_seconds_bucket)
   ```

3. **Request rate (per second):**
   ```
   rate(dynamo_frontend_requests_total[1m])
   ```

4. **Inter-token latency:**
   ```
   dynamo_frontend_inter_token_latency_seconds
   ```

Let's test Prometheus is accessible:


```bash
%%bash
# Test Prometheus API
curl -s http://localhost:${USER_PROMETHEUS_PORT}/api/v1/query?query=up | head -20

echo ""
echo "✓ Prometheus is accessible"
```

### Step 3: Get Grafana Credentials


```bash
%%bash
# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl get secret -n $NAMESPACE prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)

echo "Grafana Login Credentials:"
echo "  Username: admin"
echo "  Password: $GRAFANA_PASSWORD"
echo ""
echo "Keep these credentials handy for the next step!"
```

### Step 4: Port Forward Grafana


```bash
%%bash --bg
# Forward Grafana port (run in background)
kubectl port-forward svc/prometheus-grafana $USER_GRAFANA_PORT:80 -n $NAMESPACE &

echo "✓ Grafana UI available at http://localhost:${USER_GRAFANA_PORT}"
echo "  (To stop: pkill -f 'port-forward.*3000')"
sleep 5
```

### Step 5: Access Grafana Dashboard

1. **Open Grafana**: Navigate to http://localhost:${USER_GRAFANA_PORT}
2. **Login**: Use credentials from Step 3 (username: `admin`)
3. **Find Dashboard**:
   - Click on "Dashboards" in the left sidebar (or the hamburger menu)
   - Look for "Dynamo Dashboard" or search for "Dynamo"
4. **View Metrics**: The dashboard shows:
   - Request rates and throughput
   - Time to first token (TTFT)
   - Inter-token latency
   - Request duration
   - Input/output sequence lengths
   - GPU utilization (if DCGM exporter is installed)

### Step 6: Generate More Load to See Metrics

Let's run a benchmark to generate interesting metrics:


```bash
%%bash
# Run a small benchmark to generate metrics
aiperf profile \
  --model Qwen/Qwen2.5-1.5B-Instruct \
  --url http://localhost:${USER_FRONTEND_PORT} \
  --endpoint-type chat \
  --streaming \
  --concurrency 2 \
  --request-count 50

echo ""
echo "✓ Benchmark complete - check Grafana dashboard for updated metrics!"
```

---

## Section 5: Understanding Key Metrics

### Frontend Metrics

The Dynamo frontend exposes these key metrics:

| Metric | Description | Use Case |
|--------|-------------|----------|
| `dynamo_frontend_requests_total` | Total number of requests | Track request volume |
| `dynamo_frontend_time_to_first_token_seconds` | Time until first token appears | User experience, responsiveness |
| `dynamo_frontend_inter_token_latency_seconds` | Time between consecutive tokens | Generation speed, smoothness |
| `dynamo_frontend_request_duration_seconds` | Total request duration | Overall latency |
| `dynamo_frontend_input_tokens_total` | Input tokens processed | Input size distribution |
| `dynamo_frontend_output_tokens_total` | Output tokens generated | Output size, throughput |

### Worker Metrics

Workers expose additional metrics:

| Metric | Description | Use Case |
|--------|-------------|----------|
| `dynamo_worker_queue_size` | Requests waiting in queue | Identify backpressure |
| `dynamo_worker_active_requests` | Currently processing requests | Worker utilization |
| `dynamo_worker_kv_cache_usage` | KV cache memory usage | Memory optimization |

### Exploring Metrics in Prometheus

Try these advanced queries in Prometheus:


```bash
%%bash
# Query Prometheus API for key metrics

echo "=== Total Requests ==="
curl -s "http://localhost:${USER_PROMETHEUS_PORT}/api/v1/query?query=dynamo_frontend_requests_total" | python3 -m json.tool

echo ""
echo "=== Average Request Rate (last 5 minutes) ==="
curl -s "http://localhost:${USER_PROMETHEUS_PORT}/api/v1/query?query=rate(dynamo_frontend_requests_total[5m])" | python3 -m json.tool
```

---

## Section 6: Exercises and Exploration

### Exercise 1: Correlate Load with Latency

1. Run different concurrency levels with aiperf
2. Observe how TTFT and ITL change in Grafana
3. Find the optimal concurrency for your deployment


```bash
%%bash
# Test with low concurrency
aiperf profile \
  --model Qwen/Qwen2.5-1.5B-Instruct \
  --url http://localhost:${USER_FRONTEND_PORT} \
  --endpoint-type chat \
  --streaming \
  --concurrency 1 \
  --request-count 30

echo ""
echo "Check Grafana - note the TTFT values"
echo "Press Enter to continue with higher concurrency"
read

# Test with high concurrency
aiperf profile \
  --model Qwen/Qwen2.5-1.5B-Instruct \
  --url http://localhost:${USER_FRONTEND_PORT} \
  --endpoint-type chat \
  --streaming \
  --concurrency 8 \
  --request-count 30

echo ""
echo "Compare TTFT between low and high concurrency in Grafana"
```

### Exercise 2: Create Custom Prometheus Queries

Try creating your own queries:

1. **Average TTFT over time:**
   ```
   avg(rate(dynamo_frontend_time_to_first_token_seconds_sum[1m]))
   ```

2. **Request success rate:**
   ```
   rate(dynamo_frontend_requests_total{status="success"}[1m])
   ```

3. **Tokens per second:**
   ```
   rate(dynamo_frontend_output_tokens_total[1m])
   ```

### Exercise 3: Set Up Alerts (Optional)

Create a PrometheusRule for high latency alerts:

```yaml
# Save as high-latency-alert.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: dynamo-alerts
  namespace: YOUR_NAMESPACE
spec:
  groups:
  - name: dynamo
    interval: 30s
    rules:
    - alert: HighTimeToFirstToken
      expr: histogram_quantile(0.95, rate(dynamo_frontend_time_to_first_token_seconds_bucket[5m])) > 1.0
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High Time to First Token"
        description: "95th percentile TTFT is above 1 second"
```

Apply it:


```bash
%%bash
# Update the namespace in the file first, then apply
sed -i "s/YOUR_NAMESPACE/$NAMESPACE/g" high-latency-alert.yaml
kubectl apply -f high-latency-alert.yaml
```

### Exercise 4: Cleanup Monitoring Stack

When you're done exploring, you can remove the monitoring stack:


```bash
%%bash
# Uninstall kube-prometheus-stack (optional - only if you're done)
# helm uninstall prometheus -n $NAMESPACE

# Or keep it for future use!
echo "Monitoring stack is still running in namespace: $NAMESPACE"
echo "To remove it later, run:"
echo "  helm uninstall prometheus -n $NAMESPACE"
```

---

## Summary

### What You Learned
- ✅ How to install namespace-scoped Prometheus and Grafana
- ✅ Understanding Prometheus Operator and PodMonitors
- ✅ Configuring automatic metrics collection from Dynamo
- ✅ Creating and viewing Grafana dashboards
- ✅ Key Dynamo performance metrics
- ✅ Using Prometheus queries for analysis
- ✅ Correlating load with performance metrics

### Key Takeaways
- **Namespace-scoped monitoring** enables safe multi-tenant clusters
- **PodMonitors** automatically discover and scrape Dynamo metrics
- **Prometheus** provides powerful query language for metric analysis
- **Grafana** offers rich visualizations for real-time monitoring
- **Key metrics** like TTFT and ITL are critical for LLM performance

### Next Steps
- In **Lab 2**, you'll explore disaggregated serving and monitor the separate prefill/decode workers
- Advanced monitoring: Set up alerting rules and long-term metric storage
- Integrate with your CI/CD: Automated performance regression testing

---

## Troubleshooting

### Prometheus Not Scraping Metrics


```bash
%%bash
# Check Prometheus targets
echo "Opening Prometheus targets page..."
echo "Visit: http://localhost:${USER_PROMETHEUS_PORT}/targets"
echo ""
echo "Look for Dynamo pods in the targets list"
echo "If pods are missing, check PodMonitor configuration:"
kubectl get podmonitor -n $NAMESPACE -o yaml
```

### Grafana Dashboard Not Appearing


```bash
%%bash
# Check if dashboard ConfigMap has correct labels
kubectl get configmap -n $NAMESPACE grafana-dynamo-dashboard -o yaml | grep -A 5 labels

echo ""
echo "The ConfigMap should have label: grafana_dashboard: '1'"
```

### Can't Access Grafana


```bash
%%bash
# Check Grafana pod status
kubectl get pods -n $NAMESPACE | grep grafana

# Check Grafana logs
GRAFANA_POD=$(kubectl get pods -n $NAMESPACE | grep grafana | awk '{print $1}')
kubectl logs -n $NAMESPACE $GRAFANA_POD --tail=30
```

### Port Forwards Not Working


```bash
%%bash
# Kill all existing port-forwards and restart
pkill -f 'kubectl port-forward' || true

echo "✓ Killed existing port-forwards"
echo ""
echo "Re-run the port-forward commands from Section 4"
```

---

## Additional Resources

- 📖 [Dynamo Metrics Documentation](../../dynamo/docs/observability/metrics.md)
- 📊 [Prometheus Query Examples](https://prometheus.io/docs/prometheus/latest/querying/examples/)
- 🎨 [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/best-practices/)
- 🔔 [Prometheus Alerting](https://prometheus.io/docs/alerting/latest/overview/)


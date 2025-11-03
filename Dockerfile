FROM python:3.11-slim

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better layer caching
COPY requirements.txt /workspace/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r /workspace/requirements.txt

# Install Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install Helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && \
    chmod 700 get_helm.sh && \
    ./get_helm.sh
    
# Verify installations (optional)
RUN kubectl version --client
RUN helm version

# Copy workshop content
COPY . /workspace

RUN mkdir -p /root/.kube
# Copy kubeconfig (adjust the source path as necessary)
COPY ./config /root/.kube/

# Expose JupyterLab port
EXPOSE 8888

# Start JupyterLab
CMD ["jupyter", "lab", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--allow-root", \
     "--ServerApp.token=''", \
     "--ServerApp.password=''"]


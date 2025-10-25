FROM python:3.11-slim

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install JupyterLab and common Python packages
RUN pip install --no-cache-dir \
    jupyterlab \
    ipykernel \
    requests \
    pyyaml \
    matplotlib \
    pandas

# Copy workshop content
COPY . /workspace

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


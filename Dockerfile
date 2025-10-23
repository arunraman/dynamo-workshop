FROM python:3.11-slim

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter and common Python packages
RUN pip install --no-cache-dir \
    jupyter \
    notebook \
    ipykernel \
    requests \
    pyyaml \
    matplotlib \
    pandas

# Copy workshop content
COPY . /workspace

# Expose Jupyter port
EXPOSE 8888

# Set Jupyter configuration
ENV JUPYTER_ENABLE_LAB=no

# Start Jupyter Notebook
CMD ["jupyter", "notebook", \
     "--ip=0.0.0.0", \
     "--port=8888", \
     "--no-browser", \
     "--allow-root", \
     "--NotebookApp.token=''", \
     "--NotebookApp.password=''"]


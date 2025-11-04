#!/bin/bash

echo "🚀 Starting Dynamo Workshop..."
echo ""

# Build the Docker image
echo "📦 Building Docker image..."
docker compose build

# Start JupyterLab
echo "🎓 Starting JupyterLab..."
docker compose up -d

# Wait a moment for JupyterLab to start
sleep 3

echo ""
echo "✅ Workshop is ready!"
echo ""
echo "📓 Open your browser and navigate to:"
echo "   http://localhost:8888"
echo ""
echo "📚 Available labs:"
echo "   - Lab 1: lab1/lab1-introduction-setup.ipynb"
echo "   - Lab 2: lab2/lab2-kubernetes-deployment.ipynb"
echo "   - Lab 3: lab3/lab3-advanced-features.ipynb"
echo ""
echo "To stop the workshop, run: docker compose down"
echo ""


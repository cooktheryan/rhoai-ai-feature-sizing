#!/bin/bash
set -e

echo "Starting LlamaDeploy API server in background..."
uv run -m llama_deploy.apiserver &

echo "Waiting for API server to be ready..."
sleep 10

echo "Deploying workflows..."
uv run llamactl deploy deployment.yml

echo "API server is running. Bringing to foreground..."

echo "Waiting for UI server to be available on port 3000..."
while ! nc -z localhost 3000; do
    echo "Port 3000 not ready, waiting 2 seconds..."
    sleep 2
done

echo "Port 3000 is available. Initializing UI (this may take up to 60 seconds)..."
curl -f http://localhost:4501/deployments/rhoai-ai-feature-sizing/ui || echo "UI initialization request completed"

wait

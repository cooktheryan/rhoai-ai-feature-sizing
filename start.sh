#!/bin/bash
# Startup script for S2I Python builds

set -e

echo "---> Starting RHOAI AI Feature Sizing Platform"

# Copy environment template to create .env if it doesn't exist
if [ ! -f "src/.env" ]; then
    echo "---> Creating environment file from template"
    cp env.template src/.env
fi

# Create output directories
mkdir -p output/python-rag output/session-contexts

echo "---> Starting LlamaDeploy API server in background"
nohup uv run -m llama_deploy.apiserver --host 0.0.0.0 --port ${PORT:-4501} > llamadeploy.log 2>&1 &
LLAMADEPLOY_PID=$!

# Wait for API server to start
echo "---> Waiting for LlamaDeploy API server to start..."
sleep 15

echo "---> Deploying workflows"
uv run llamactl deploy deployment.yml || echo "Warning: Workflow deployment failed"

echo "---> RHOAI AI Feature Sizing Platform started"
echo "---> LlamaDeploy PID: $LLAMADEPLOY_PID"
echo "---> API available at: http://0.0.0.0:${PORT:-4501}"
echo "---> UI available at: http://0.0.0.0:${PORT:-4501}/deployments/rhoai-ai-feature-sizing/ui"

# Keep the container running
wait $LLAMADEPLOY_PID
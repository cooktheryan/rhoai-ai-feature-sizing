#!/bin/bash
# API-only startup script

set -e

echo "---> Starting RHOAI AI Feature Sizing API Server (API only)"

# Add Python virtual environment to PATH
source /opt/app-root/bin/activate

# Copy environment template to create .env if it doesn't exist
if [ ! -f "src/.env" ]; then
    echo "---> Creating environment file from template"
    cp env.template src/.env
fi

echo "---> Starting LlamaDeploy API server on 0.0.0.0:4501"
exec python -m llama_deploy.apiserver --host 0.0.0.0 --port ${PORT:-4501}
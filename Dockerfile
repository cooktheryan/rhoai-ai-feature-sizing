# Multi-stage build for RHOAI AI Feature Sizing with LlamaDeploy
# For Apple Silicon Macs use: linux/arm64
# For Intel Macs use: linux/amd64
FROM --platform=linux/amd64 python:3.12-slim AS base

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV UV_NO_CACHE=1
ENV PORT=4501

# Install system dependencies including Node.js
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install uv for dependency management
RUN pip install --no-cache-dir uv

# Create application directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock* ./
COPY env.template ./

# Install Python dependencies (with dev dependencies for tooling)
RUN uv sync --frozen && chmod -R g+w .venv

# UI build stage
FROM base AS ui-builder

# Copy UI source
COPY ui/ ./ui/
WORKDIR /app/ui

# Install and build UI (development dependencies included for build)
RUN npm ci
RUN npm run build

# Final production stage
FROM base AS production

# Copy UI build artifacts
COPY --from=ui-builder /app/ui/node_modules ./ui/node_modules
COPY --from=ui-builder /app/ui/package.json ./ui/
COPY --from=ui-builder /app/ui/tsconfig.json ./ui/
COPY --from=ui-builder /app/ui/index.ts ./ui/

# Copy Python application files
COPY src/ ./src/
COPY deployment.yml ./
COPY data/ ./data/

# Create necessary directories
RUN mkdir -p output/python-rag output/session-contexts

# Copy environment template and create .env
RUN cp env.template src/.env

# Set permissions for OpenShift (any user can access)
RUN chmod -R g+w /app && \
    chmod g+w /tmp

# Expose LlamaDeploy port (UI is served through LlamaDeploy)
EXPOSE 4501

# Health check for LlamaDeploy API
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4501/status/ || exit 1

# Create startup script
RUN cat << 'EOF' > /app/start.sh
#!/bin/bash
set -e

echo "Starting RHOAI AI Feature Sizing Platform..."

# Generate RAG indices if data exists
if [ -d "data" ] && [ "$(ls -A data)" ]; then
    echo "Generating RAG indices..."
    uv run generate || echo "Warning: RAG index generation failed"
fi

# Start LlamaDeploy API server in background
echo "Starting LlamaDeploy API server..."
uv run -m llama_deploy.apiserver --host 0.0.0.0 --port ${PORT} &
LLAMADEPLOY_PID=$!

# Wait for API server to start
echo "Waiting for LlamaDeploy to start..."
sleep 15

# Deploy workflows
echo "Deploying workflows..."
uv run llamactl deploy deployment.yml || echo "Warning: Workflow deployment failed"

echo "RHOAI AI Feature Sizing Platform started successfully!"
echo "API available at: http://0.0.0.0:${PORT}"
echo "UI available at: http://0.0.0.0:${PORT}/deployments/rhoai-ai-feature-sizing/ui"

# Keep container running
wait $LLAMADEPLOY_PID
EOF

RUN chmod +x /app/start.sh

# Start the application
CMD ["/app/start.sh"]
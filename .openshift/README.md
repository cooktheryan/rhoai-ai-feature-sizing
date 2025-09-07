# OpenShift Deployment Guide

This directory contains everything needed to deploy the RHOAI AI Feature Sizing Platform to OpenShift using git-based deployment (no container registry required).

## Quick Deployment

### Option 1: Using OpenShift Web Console

1. **Create New Project**:
   - Go to OpenShift Web Console
   - Click "Create Project" or use existing project

2. **Add from Git**:
   - Click "Add+" → "From Git"
   - Enter your git repository URL
   - OpenShift will automatically detect the `.openshift` configuration

3. **Configure Environment**:
   - Set environment variables for your LLM provider
   - Add API keys as secrets

### Option 2: Using oc CLI

```bash
# Create new project
oc new-project rhoai-ai-feature-sizing

# Process and create the template
oc process -f .openshift/templates/rhoai-ai-feature-sizing.yaml \
  -p SOURCE_REPOSITORY_URL=https://github.com/your-org/rhoai-ai-feature-sizing.git \
  -p LLM_PROVIDER=openshift_ai \
  -p OPENSHIFT_AI_API_KEY=your-api-key \
  -p OPENSHIFT_AI_BASE_URL=https://your-openshift-ai-endpoint/v1 \
  | oc create -f -

# Start the build
oc start-build rhoai-ai-feature-sizing
```

### Option 3: Template-based Deployment

```bash
# Add template to OpenShift
oc create -f .openshift/templates/rhoai-ai-feature-sizing.yaml

# Create app from template
oc new-app rhoai-ai-feature-sizing \
  -p SOURCE_REPOSITORY_URL=https://github.com/your-org/rhoai-ai-feature-sizing.git \
  -p LLM_PROVIDER=openshift_ai \
  -p OPENSHIFT_AI_API_KEY=your-api-key \
  -p OPENSHIFT_AI_BASE_URL=https://your-openshift-ai-endpoint/v1
```

## Configuration

### Environment Variables

The template supports these LLM providers:

**OpenAI**:
```bash
-p LLM_PROVIDER=openai
-p OPENAI_API_KEY=sk-...
```

**Anthropic**:
```bash
-p LLM_PROVIDER=anthropic  
-p ANTHROPIC_API_KEY=sk-ant-...
```

**OpenShift AI**:
```bash
-p LLM_PROVIDER=openshift_ai
-p OPENSHIFT_AI_API_KEY=your-key
-p OPENSHIFT_AI_BASE_URL=https://your-endpoint/v1
```

### Secrets Management

API keys are stored as OpenShift secrets and mounted as environment variables. You can also create secrets manually:

```bash
# Create secret with API keys
oc create secret generic rhoai-ai-feature-sizing-secrets \
  --from-literal=openshift-ai-api-key=your-key \
  --from-literal=openshift-ai-base-url=https://your-endpoint/v1
```

## Build Process

The deployment uses OpenShift's Source-to-Image (S2I) build process:

1. **Pre-build** (`.openshift/action_hooks/pre_build`):
   - Installs `uv` package manager

2. **Build** (`.openshift/action_hooks/build`):
   - Syncs Python dependencies with `uv sync`
   - Installs and builds Node.js UI components
   - Generates RAG indices

3. **Start** (`.openshift/action_hooks/start`):
   - Starts LlamaDeploy API server
   - Deploys workflows
   - Serves the application

## Accessing the Application

After deployment, the application will be available at:

- **API**: `https://rhoai-ai-feature-sizing-api-[project].apps.[cluster-domain]/`
- **UI**: `https://rhoai-ai-feature-sizing-ui-[project].apps.[cluster-domain]/`

Or combined UI access via:
- `https://rhoai-ai-feature-sizing-api-[project].apps.[cluster-domain]/deployments/rhoai-ai-feature-sizing/ui`

## Monitoring

### Check Build Status
```bash
oc logs -f bc/rhoai-ai-feature-sizing
```

### Check Application Logs
```bash
oc logs -f dc/rhoai-ai-feature-sizing
```

### Check Application Status
```bash
oc status
oc get pods
oc get routes
```

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check build logs: `oc logs -f bc/rhoai-ai-feature-sizing`
   - Ensure all dependencies are in `pyproject.toml`

2. **Application Not Starting**:
   - Check deployment logs: `oc logs -f dc/rhoai-ai-feature-sizing`
   - Verify environment variables and secrets

3. **UI Not Loading**:
   - Check routes: `oc get routes`
   - Verify both API and UI services are running

### Resource Requirements

The application requires:
- **Memory**: 1-2Gi 
- **CPU**: 500m-1000m
- **Storage**: Ephemeral (no persistent volumes required)

### Scaling

```bash
# Scale up
oc scale dc/rhoai-ai-feature-sizing --replicas=2

# Scale down  
oc scale dc/rhoai-ai-feature-sizing --replicas=1
```

## Security Notes

- API keys are stored as OpenShift secrets
- TLS termination is enabled on routes
- Application runs as non-root user
- No privileged containers required
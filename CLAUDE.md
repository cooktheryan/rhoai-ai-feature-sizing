# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Python Backend
```bash
# Install dependencies
uv sync

# Generate vector indices for RAG
uv run generate

# Start LlamaDeploy API server
uv run -m llama_deploy.apiserver

# Deploy workflows
uv run llamactl deploy deployment.yml

# Type checking
uv run mypy src/

# Run tests
uv run pytest
```

### TypeScript Frontend
```bash
# Install dependencies (in ui/ directory)
cd ui && npm install

# Development mode with hot reload
npm run dev

# Production build
npm run build
```

### Development Workflow
1. Start LlamaDeploy API server: `uv run -m llama_deploy.apiserver` (runs on port 4501)
2. Deploy workflows: `uv run llamactl deploy deployment.yml`
3. Start frontend: `cd ui && npm run dev` (serves on port 3000)
4. Access UI at: http://localhost:4501/deployments/rhoai-ai-feature-sizing/ui

## OpenShift Deployment

The project includes `.openshift/` configuration for git-based deployment to OpenShift (no container registry required):

- **Templates**: OpenShift template in `.openshift/templates/`
- **Action Hooks**: Build and start scripts in `.openshift/action_hooks/`
- **Documentation**: Detailed deployment guide in `.openshift/README.md`

Deploy with: `oc new-app` using the git repository URL, and OpenShift will automatically detect and use the `.openshift` configuration.

## Architecture Overview

This is a production-ready multi-agent system for analyzing Request for Enhancement (RFE) descriptions. The system uses **LlamaDeploy** for Python workflow orchestration and **@llamaindex/server** for the TypeScript frontend.

### Key Components

**Python Backend (LlamaDeploy)**:
- Main workflow: `src/rfe_builder_workflow.py` - Multi-agent RFE analysis
- Secondary workflow: `src/jira_rfe_to_architecture_workflow.py` - Architecture generation from existing RFEs
- Agent management: `src/agents.py` - Coordinates 16 specialized AI agents
- RAG system: `src/rag.py` and `src/generate.py` - Vector retrieval for domain knowledge
- Settings: `src/settings.py` - LLM and embedding model configuration

**TypeScript Frontend**:
- UI configuration: `ui/index.ts` - Chat interface powered by @llamaindex/server
- Custom components: `ui/components/` - Progress tracking and agent analysis display
- Real-time streaming: Connects to LlamaDeploy API for workflow updates

**Agent System**:
- 16 specialized personas defined in `src/agents/*.yaml`
- Each agent has domain expertise (Product Manager, UX Architect, Staff Engineer, etc.)
- RAG-powered knowledge bases from local directories and GitHub repositories
- Parallel analysis with synthesis into comprehensive deliverables

### Data Flow

1. **Preparation**: Run `uv run generate` to create vector indices from data sources
2. **Analysis**: User submits RFE via chat UI
3. **Multi-Agent Processing**: LlamaDeploy orchestrates all agents simultaneously
4. **RAG Retrieval**: Each agent queries domain-specific knowledge bases
5. **Synthesis**: Combine analyses into architecture diagrams, component teams, timelines
6. **Artifacts**: Generate structured deliverables (RFE documents, epics/stories, etc.)

### Configuration

- **LLM Models**: Configure in `src/settings.py` (OpenAI GPT-4 by default)
- **Agent Personas**: Add/modify YAML files in `src/agents/`
- **Knowledge Sources**: Place documentation in `data/` or configure GitHub repos in agent YAML
- **UI Customization**: Modify `ui/index.ts` for starter questions and component configuration
- **Environment Setup**: 
  1. Copy `env.template` to `env.local`
  2. Fill in your actual API keys and endpoints in `env.local`
  3. Copy `env.local` to `src/.env` for the application to use
  4. **Never commit `env.local` or `src/.env` to version control**

### File Structure

```
/
├── src/                    # Python workflow engine
│   ├── agents/            # Agent persona configurations (YAML)
│   ├── prompts/           # Structured prompts for analysis
│   └── *.py              # Core workflow and RAG components
├── ui/                    # TypeScript frontend
│   ├── components/        # Custom UI components
│   └── index.ts          # Main UI configuration
├── data/                  # Local knowledge bases
├── deployment.yml         # LlamaDeploy configuration
└── pyproject.toml        # Python dependencies and scripts
```

### Development Notes

- The system requires OpenAI API keys configured in `src/.env`
- Vector indices are stored in `output/python-rag/{agent_name}/` after running `uv run generate`
- LlamaDeploy provides production-grade orchestration with built-in monitoring
- Frontend uses real-time streaming for workflow progress updates
- Agent configurations use JSON Schema validation (`src/agents/agent-schema.json`)
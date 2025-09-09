FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

COPY pyproject.toml ./
COPY uv.lock ./
COPY README.md ./

RUN pip install uv && uv sync --frozen

COPY src ./src
COPY ui ./ui
COPY data ./data
COPY deployment.yml ./

# Install UI dependencies
WORKDIR /app/ui
RUN npm i -g pnpm
RUN pnpm install
WORKDIR /app

RUN uv run generate

RUN chmod -R g+w .venv/

ENV HOME=/app
RUN mkdir -p /app/.config/llamactl && chmod -R 777 /app/.config

EXPOSE 4501

COPY startup.sh ./
RUN chmod +x startup.sh

CMD ["./startup.sh"]

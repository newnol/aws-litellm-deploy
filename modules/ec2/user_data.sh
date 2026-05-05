#!/usr/bin/env bash
# =============================================================================
# EC2 User Data Script
# =============================================================================
# Installs Docker, Docker Compose, and configures LiteLLM Proxy.
# =============================================================================

set -euo pipefail

# Log everything
exec > >(tee /var/log/user-data.log) 2>&1
echo "=== Starting user data script at $(date) ==="

# --- System Updates ---
yum update -y

# --- Install Docker ---
echo "Installing Docker..."
yum install -y docker
touch /etc/sysconfig/docker
systemctl enable docker
systemctl start docker

# --- Install Docker Compose ---
echo "Installing Docker Compose..."
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

# --- Add ec2-user to docker group ---
usermod -aG docker ec2-user

# --- Create LiteLLM directory ---
mkdir -p /opt/litellm/nginx
chown -R ec2-user:ec2-user /opt/litellm

# --- Install Nginx config ---
cat > /opt/litellm/nginx/nginx.conf << 'NGINX_EOF'
events {
    worker_connections 1024;
}

http {
    upstream litellm {
        server litellm:4000;
    }

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://litellm;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        location /health {
            proxy_pass http://litellm/health;
            access_log off;
        }
    }
}
NGINX_EOF

# --- Create docker-compose.yml ---
cat > /opt/litellm/docker-compose.yml << 'COMPOSE_EOF'
version: "3.8"

services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    container_name: litellm-proxy
    restart: unless-stopped
    ports:
      - "0.0.0.0:4000:4000"
    volumes:
      - ./litellm_config.yaml:/app/litellm_config.yaml:ro
    command:
      - "--config"
      - "/app/litellm_config.yaml"
      - "--port"
      - "4000"
      - "--host"
      - "0.0.0.0"
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  nginx:
    image: nginx:alpine
    container_name: litellm-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      litellm:
        condition: service_healthy
COMPOSE_EOF

# --- Create .env file ---
cat > /opt/litellm/.env << 'ENV_EOF'
DATABASE_URL=postgresql://${dsql_endpoint}/litellm
LITELLM_MASTER_KEY=${litellm_master_key}
ENV_EOF
chmod 600 /opt/litellm/.env

# --- Create litellm_config.yaml ---
cat > /opt/litellm/litellm_config.yaml << 'CONFIG_EOF'
model_list:
  - model_name: "gpt-4"
    litellm_params:
      model: "gpt-4"
      api_key: "os.environ/OPENAI_API_KEY"
  - model_name: "gpt-3.5-turbo"
    litellm_params:
      model: "gpt-3.5-turbo"
      api_key: "os.environ/OPENAI_API_KEY"

litellm_settings:
  set_verbose: false
  num_retries: 3
  request_timeout: 300
CONFIG_EOF

# --- Start services ---
echo "Starting LiteLLM Proxy..."
cd /opt/litellm
docker compose up -d

echo "=== User data script completed at $(date) ==="

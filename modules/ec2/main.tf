################################################################################
# EC2 Module — t3.micro with Docker Compose + Elastic IP
################################################################################

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script to install Docker and start LiteLLM
locals {
  user_data = <<-USERDATA
    #!/bin/bash
    set -e

    # Log output for debugging
    exec > /var/log/user-data.log 2>&1

    echo "=== Starting user data script ==="

    # Update system
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user

    # Install Docker Compose v2
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    ln -sf /usr/local/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose

    # Create swap file (2GB for t3.micro with 1GB RAM)
    dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

    # Create app directory and nginx directory
    mkdir -p /opt/litellm/nginx
    cd /opt/litellm

    # Create .env file for Docker Compose
    cat > .env << 'ENVEOF'
    LITELLM_MASTER_KEY=${litellm_master_key}
    LITELLM_SALT_KEY=${litellm_salt_key}
    DSQL_HOST=${dsql_endpoint}
    DSQL_PORT=5432
    DSQL_USER=admin
    DSQL_PASSWORD=
    DSQL_DB=litellm
    ENVEOF

    # Create litellm_config.yaml
    cat > litellm_config.yaml << 'CONFIGEOF'
    model_list: []
    general_settings:
      master_key: os.environ/LITELLM_MASTER_KEY
      database_url: os.environ/DATABASE_URL
    CONFIGEOF

    # Create nginx.conf
    cat > nginx/nginx.conf << 'NGINXEOF'
    upstream litellm_backend {
        server litellm:4000;
    }

    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=30r/s;

    server {
        listen 80;
        server_name _;

        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "no-referrer-when-downgrade" always;

        gzip on;
        gzip_types text/plain application/json application/javascript text/css;
        gzip_min_length 1000;

        location /nginx-health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        location / {
            limit_req zone=api_limit burst=50 nodelay;

            proxy_pass http://litellm_backend;
            proxy_http_version 1.1;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";

            proxy_connect_timeout 60s;
            proxy_send_timeout 120s;
            proxy_read_timeout 120s;

            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 4k;
        }

        access_log /var/log/nginx/litellm_access.log;
        error_log /var/log/nginx/litellm_error.log;
    }
    NGINXEOF

    # Create docker-compose.yml (inline from template)
    cat > docker-compose.yml << 'COMPOSEEOF'
    version: "3.8"

    services:
      nginx:
        image: nginx:alpine
        container_name: nginx-proxy
        restart: unless-stopped
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro
          - nginx_logs:/var/log/nginx
        depends_on:
          - litellm
        healthcheck:
          test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/nginx-health"]
          interval: 30s
          timeout: 10s
          start_period: 10s
          retries: 3
        deploy:
          resources:
            limits:
              memory: 128M
            reservations:
              memory: 64M
        logging:
          driver: json-file
          options:
            max-size: "10m"
            max-file: "3"

      litellm:
        image: ghcr.io/berriai/litellm:main-latest
        container_name: litellm-proxy
        restart: unless-stopped
        expose:
          - "4000"
        environment:
          - LITELLM_MASTER_KEY=$${LITELLM_MASTER_KEY}
          - LITELLM_SALT_KEY=$${LITELLM_SALT_KEY}
          - DATABASE_URL=postgresql://admin@$${DSQL_HOST}:5432/litellm
          - STORE_MODEL_IN_DB=true
          - LITELLM_LOG=INFO
        volumes:
          - ./litellm_config.yaml:/app/config.yaml
        command:
          - "--config"
          - "/app/config.yaml"
          - "--port"
          - "4000"
          - "--host"
          - "0.0.0.0"
        healthcheck:
          test: ["CMD", "python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/readiness')"]
          interval: 30s
          timeout: 10s
          start_period: 60s
          retries: 3
        deploy:
          resources:
            limits:
              memory: 512M
            reservations:
              memory: 256M
        logging:
          driver: json-file
          options:
            max-size: "10m"
            max-file: "3"

    volumes:
      nginx_logs:
    COMPOSEEOF

    # Pull image and start
    docker compose pull
    docker compose up -d

    # Install CloudWatch agent (basic monitoring)
    dnf install -y amazon-cloudwatch-agent

    echo "=== User data script completed ==="
  USERDATA
}

# EC2 Instance
resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name
  iam_instance_profile   = var.instance_profile

  user_data = base64encode(local.user_data)

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2"
    Project     = var.project_name
    Environment = var.environment
    Owner       = "newnol"
    ManagedBy   = "terraform"
  }
}

# Elastic IP (static IP that persists across stop/start)
resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-eip"
    Project     = var.project_name
    Environment = var.environment
    Owner       = "newnol"
    ManagedBy   = "terraform"
  }
}

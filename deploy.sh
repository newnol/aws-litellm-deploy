#!/usr/bin/env bash
# =============================================================================
# LiteLLM Proxy - Deploy Script
# =============================================================================
# Convenience wrapper for Terraform commands and EC2 management.
# Usage: ./deploy.sh <command>
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/envs/prod"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Get elastic IP from Terraform output
get_elastic_ip() {
    cd "${ENV_DIR}"
    terraform output -raw elastic_ip 2>/dev/null
}

# Get SSH key path
get_ssh_key() {
    cd "${ENV_DIR}"
    terraform output -raw ssh_command 2>/dev/null | grep -oP '(?<=-i )[^ ]+' || echo "~/.ssh/litellm.pem"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_init() {
    log_info "Initializing Terraform..."
    cd "${ENV_DIR}"
    terraform init
    log_ok "Terraform initialized."
}

cmd_plan() {
    log_info "Creating Terraform plan..."
    cd "${ENV_DIR}"
    terraform plan -out=tfplan
    log_ok "Plan saved to tfplan."
}

cmd_apply() {
    log_info "Applying Terraform plan..."
    cd "${ENV_DIR}"
    if [[ -f tfplan ]]; then
        terraform apply tfplan
    else
        terraform apply
    fi
    log_ok "Infrastructure deployed!"

    # Show connection info
    echo ""
    log_info "Connection info:"
    echo "  Elastic IP: $(get_elastic_ip)"
    echo "  SSH:        $(terraform output -raw ssh_command 2>/dev/null || echo 'N/A')"
    echo "  LiteLLM:    http://$(get_elastic_ip):4000"
    echo ""
}

cmd_destroy() {
    log_warn "This will destroy ALL infrastructure!"
    read -p "Are you sure? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        cd "${ENV_DIR}"
        terraform destroy
        log_ok "Infrastructure destroyed."
    else
        log_info "Aborted."
    fi
}

cmd_ssh() {
    local ip
    ip=$(get_elastic_ip)
    local key
    key=$(get_ssh_key)
    log_info "Connecting to ${ip}..."
    ssh -i "${key}" ec2-user@"${ip}"
}

cmd_status() {
    local ip
    ip=$(get_elastic_ip)
    log_info "Checking status..."
    echo "  Elastic IP: ${ip}"
    echo "  LiteLLM:    http://${ip}:4000"
    echo "  Health:     $(curl -s -o /dev/null -w '%{http_code}' "http://${ip}:4000/health" 2>/dev/null || echo 'unreachable')"
}

cmd_logs() {
    local ip
    ip=$(get_elastic_ip)
    local key
    key=$(get_ssh_key)
    log_info "Fetching logs from EC2..."
    ssh -i "${key}" ec2-user@"${ip}" 'cd /opt/litellm && docker compose logs --tail=50'
}

cmd_restart() {
    local ip
    ip=$(get_elastic_ip)
    local key
    key=$(get_ssh_key)
    log_info "Restarting LiteLLM on EC2..."
    ssh -i "${key}" ec2-user@"${ip}" 'cd /opt/litellm && docker compose restart'
    log_ok "Restarted."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

case "${1:-help}" in
    init)     cmd_init ;;
    plan)     cmd_plan ;;
    apply)    cmd_apply ;;
    destroy)  cmd_destroy ;;
    ssh)      cmd_ssh ;;
    status)   cmd_status ;;
    logs)     cmd_logs ;;
    restart)  cmd_restart ;;
    *)
        echo "Usage: ./deploy.sh <command>"
        echo ""
        echo "Commands:"
        echo "  init      Initialize Terraform"
        echo "  plan      Create Terraform plan"
        echo "  apply     Apply Terraform plan (deploy infrastructure)"
        echo "  destroy   Destroy all infrastructure"
        echo "  ssh       SSH into the EC2 instance"
        echo "  status    Check deployment status"
        echo "  logs      View container logs"
        echo "  restart   Restart LiteLLM containers"
        ;;
esac

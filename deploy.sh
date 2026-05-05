#!/usr/bin/env bash
# ============================================================
# deploy.sh — Unified deploy script for LiteLLM on AWS
# Architecture: EC2 t3.micro + Aurora dSQL + Docker Compose
# Usage: ./deploy.sh <environment> <command>
# Example: ./deploy.sh prod plan
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV="${1:-}"
CMD="${2:-help}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; }
info() { echo -e "${BLUE}[i]${NC} $*"; }

# Validate environment
validate_env() {
  if [[ -z "$ENV" ]]; then
    error "Environment required. Usage: ./deploy.sh <env> <command>"
    echo " Environments: dev, staging, prod"
    exit 1
  fi
  local env_dir="${SCRIPT_DIR}/envs/${ENV}"
  if [[ ! -d "$env_dir" ]]; then
    error "Environment '${ENV}' not found at ${env_dir}"
    exit 1
  fi
}

# Run terraform command in the correct directory
tf() {
  cd "${SCRIPT_DIR}/envs/${ENV}"
  terraform "$@"
}

case "$CMD" in
  init)
    validate_env
    info "Initializing Terraform for ${ENV}..."
    tf init -upgrade
    log "Terraform initialized"
    ;;

  plan)
    validate_env
    info "Planning changes for ${ENV}..."
    tf plan -out=tfplan
    log "Plan saved to tfplan"
    ;;

  apply)
    validate_env
    if [[ ! -f "${SCRIPT_DIR}/envs/${ENV}/tfplan" ]]; then
      error "No tfplan found. Run './deploy.sh ${ENV} plan' first"
      exit 1
    fi
    warn "Applying changes to ${ENV}..."
    tf apply tfplan
    log "Changes applied successfully"
    ;;

  deploy)
    validate_env
    info "Full deploy to ${ENV}: init → plan → apply"
    tf init -upgrade
    tf plan -out=tfplan
    warn "Review the plan above. Apply? (y/N)"
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      tf apply tfplan
      log "Deploy complete!"
      echo ""
      info "=== Connection Info ==="
      tf output
    else
      warn "Deploy cancelled"
    fi
    ;;

  status)
    validate_env
    info "Status for ${ENV}:"
    cd "${SCRIPT_DIR}/envs/${ENV}"
    echo ""
    echo "=== Terraform Outputs ==="
    terraform output
    echo ""
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null || echo "")
    if [[ -n "$ELASTIC_IP" ]]; then
      echo "=== EC2 Instance ==="
      echo "Public IP: ${ELASTIC_IP}"
      echo "LiteLLM: http://${ELASTIC_IP}:4000"
      echo ""
      echo "=== Docker Status (via SSH) ==="
      KEY_NAME=$(terraform output -raw key_name 2>/dev/null || echo "")
      if [[ -n "$KEY_NAME" ]]; then
        ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" ec2-user@"$ELASTIC_IP" \
          "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null || \
          warn "SSH not available. Check key pair and security group."
      fi
    fi
    ;;

  logs)
    validate_env
    cd "${SCRIPT_DIR}/envs/${ENV}"
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null || echo "")
    KEY_NAME=$(terraform output -raw key_name 2>/dev/null || echo "")
    if [[ -z "$ELASTIC_IP" ]]; then
      error "No Elastic IP found. Deploy first."
      exit 1
    fi
    info "Tailing Docker logs on ${ELASTIC_IP}..."
    ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" ec2-user@"$ELASTIC_IP" \
      "docker logs -f litellm-proxy" 2>/dev/null || \
      error "SSH connection failed. Check key pair and security group."
    ;;

  ssh)
    validate_env
    cd "${SCRIPT_DIR}/envs/${ENV}"
    ELASTIC_IP=$(terraform output -raw elastic_ip 2>/dev/null || echo "")
    KEY_NAME=$(terraform output -raw key_name 2>/dev/null || echo "")
    if [[ -z "$ELASTIC_IP" ]]; then
      error "No Elastic IP found. Deploy first."
      exit 1
    fi
    info "SSH into ${ELASTIC_IP}..."
    ssh -o StrictHostKeyChecking=no -i "${KEY_NAME}.pem" ec2-user@"$ELASTIC_IP"
    ;;

  destroy)
    validate_env
    warn "⚠️  This will DESTROY all resources in ${ENV}!"
    warn "Type the environment name '${ENV}' to confirm:"
    read -r confirm
    if [[ "$confirm" == "$ENV" ]]; then
      info "Planning destroy..."
      tf plan -destroy -out=destroy.tfplan
      warn "Final confirmation. Apply destroy plan? (y/N)"
      read -r final
      if [[ "$final" =~ ^[Yy]$ ]]; then
        tf apply destroy.tfplan
        log "All resources destroyed"
      else
        warn "Destroy cancelled"
      fi
    else
      error "Confirmation failed. Destroy cancelled."
    fi
    ;;

  output)
    validate_env
    cd "${SCRIPT_DIR}/envs/${ENV}"
    terraform output
    ;;

  fmt)
    info "Formatting Terraform files..."
    terraform fmt -recursive "$SCRIPT_DIR"
    log "Files formatted"
    ;;

  validate)
    validate_env
    info "Validating Terraform config for ${ENV}..."
    tf validate
    log "Config is valid"
    ;;

  help|*)
    echo ""
    echo "Usage: ./deploy.sh <environment> <command>"
    echo ""
    echo "Environments: dev, staging, prod"
    echo ""
    echo "Commands:"
    echo "  init        Initialize Terraform"
    echo "  plan        Plan changes (save to tfplan)"
    echo "  apply       Apply saved plan"
    echo "  deploy      Full deploy: init → plan → apply"
    echo "  status      Show deployment status"
    echo "  logs        Tail Docker logs via SSH"
    echo "  ssh         SSH into EC2 instance"
    echo "  destroy     Destroy all resources (with confirmation)"
    echo "  output      Show Terraform outputs"
    echo "  fmt         Format Terraform files"
    echo "  validate    Validate Terraform config"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh prod plan"
    echo "  ./deploy.sh prod deploy"
    echo "  ./deploy.sh prod status"
    echo "  ./deploy.sh prod logs"
    echo "  ./deploy.sh prod ssh"
    echo ""
    ;;
esac

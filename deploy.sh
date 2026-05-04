#!/usr/bin/env bash
# ============================================================
# deploy.sh — Unified deploy script for LiteLLM AWS
# Usage: ./deploy.sh <env> <command>
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

log()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[✗]${NC} $*" >&2; }
info()  { echo -e "${BLUE}[i]${NC} $*"; }

# Validate environment
validate_env() {
    if [[ -z "$ENV" ]]; then
        error "Environment required. Usage: ./deploy.sh <env> <command>"
        echo "  Environments: dev, staging, prod"
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
            tf output deploy_commands
        else
            warn "Deploy cancelled"
        fi
        ;;

    build)
        validate_env
        info "Building and pushing Docker image..."
        
        # Get ECR URL from Terraform output
        cd "${SCRIPT_DIR}/envs/${ENV}"
        ECR_URL=$(terraform output -raw ecr_repository_url)
        REGION=$(terraform var -raw aws_region 2>/dev/null || echo "ap-southeast-1")
        
        # Login to ECR
        aws ecr get-login-password --region "$REGION" | \
            docker login --username AWS --password-stdin "$ECR_URL"
        
        # Build and push
        cd "$SCRIPT_DIR"
        docker build -t "${ECR_URL}:latest" .
        docker push "${ECR_URL}:latest"
        
        log "Image pushed to ${ECR_URL}:latest"
        ;;

    force-deploy)
        validate_env
        info "Forcing new ECS deployment..."
        cd "${SCRIPT_DIR}/envs/${ENV}"
        CLUSTER=$(terraform output -raw ecs_cluster_name)
        SERVICE=$(terraform output -raw ecs_service_name)
        REGION=$(terraform var -raw aws_region 2>/dev/null || echo "ap-southeast-1")
        
        aws ecs update-service \
            --cluster "$CLUSTER" \
            --service "$SERVICE" \
            --force-new-deployment \
            --region "$REGION"
        
        log "New deployment triggered"
        ;;

    logs)
        validate_env
        cd "${SCRIPT_DIR}/envs/${ENV}"
        LOG_GROUP=$(terraform output -raw cloudwatch_log_group)
        aws logs tail "$LOG_GROUP" --follow
        ;;

    status)
        validate_env
        info "Status for ${ENV}:"
        cd "${SCRIPT_DIR}/envs/${ENV}"
        echo ""
        echo "=== Terraform Outputs ==="
        terraform output
        echo ""
        echo "=== ECS Service ==="
        CLUSTER=$(terraform output -raw ecs_cluster_name)
        SERVICE=$(terraform output -raw ecs_service_name)
        aws ecs describe-services \
            --cluster "$CLUSTER" \
            --services "$SERVICE" \
            --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,TaskDef:taskDefinition}' \
            --output table
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
        echo "Usage: ./deploy.sh <env> <command>"
        echo ""
        echo "Environments: dev, staging, prod"
        echo ""
        echo "Commands:"
        echo "  init         Initialize Terraform"
        echo "  plan         Plan changes (save to tfplan)"
        echo "  apply        Apply saved plan"
        echo "  deploy       Full deploy: init → plan → apply"
        echo "  build        Build & push Docker image to ECR"
        echo "  force-deploy Force new ECS deployment"
        echo "  logs         Tail CloudWatch logs"
        echo "  status       Show deployment status"
        echo "  destroy      Destroy all resources (with confirmation)"
        echo "  output       Show Terraform outputs"
        echo "  fmt          Format Terraform files"
        echo "  validate     Validate Terraform config"
        echo ""
        echo "Examples:"
        echo "  ./deploy.sh prod plan"
        echo "  ./deploy.sh prod deploy"
        echo "  ./deploy.sh prod build"
        echo "  ./deploy.sh prod logs"
        echo ""
        ;;
esac

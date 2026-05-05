# =============================================================================
# LiteLLM Proxy - Makefile
# =============================================================================
# Convenience targets for deployment and management.
# =============================================================================

.PHONY: help init plan apply destroy ssh status logs restart

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	./deploy.sh init

plan: ## Create Terraform plan
	./deploy.sh plan

apply: ## Deploy infrastructure
	./deploy.sh apply

destroy: ## Destroy infrastructure
	./deploy.sh destroy

ssh: ## SSH into EC2
	./deploy.sh ssh

status: ## Check status
	./deploy.sh status

logs: ## View logs
	./deploy.sh logs

restart: ## Restart services
	./deploy.sh restart

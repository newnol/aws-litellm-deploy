.PHONY: help init plan apply deploy build force-deploy logs status destroy fmt validate

ENV ?= prod

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	./deploy.sh $(ENV) init

plan: ## Plan changes
	./deploy.sh $(ENV) plan

apply: ## Apply saved plan
	./deploy.sh $(ENV) apply

deploy: ## Full deploy (init → plan → apply)
	./deploy.sh $(ENV) deploy

build: ## Build & push Docker image
	./deploy.sh $(ENV) build

force-deploy: ## Force new ECS deployment
	./deploy.sh $(ENV) force-deploy

logs: ## Tail CloudWatch logs
	./deploy.sh $(ENV) logs

status: ## Show deployment status
	./deploy.sh $(ENV) status

destroy: ## Destroy all resources
	./deploy.sh $(ENV) destroy

fmt: ## Format Terraform files
	./deploy.sh fmt

validate: ## Validate Terraform config
	./deploy.sh $(ENV) validate

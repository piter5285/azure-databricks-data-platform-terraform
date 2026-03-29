# ─────────────────────────────────────────────
# Data Platform Terraform Makefile
# Usage: make <target> ENV=dev|prep|prod
# ─────────────────────────────────────────────

ENV ?= dev
TFVARS_FILE ?= terraform.tfvars

.PHONY: help init validate plan apply destroy fmt global-init global-plan global-apply

help:
	@echo ""
	@echo "Usage: make <target> ENV=dev|prep|prod"
	@echo ""
	@echo "Targets:"
	@echo "  global-init      Init global Terraform state (run once)"
	@echo "  global-plan      Plan global resources (Unity Catalog metastore)"
	@echo "  global-apply     Apply global resources"
	@echo "  init             Init environment state"
	@echo "  validate         Validate Terraform configs"
	@echo "  plan             Plan environment (ENV=dev|prep|prod)"
	@echo "  apply            Apply environment"
	@echo "  destroy          Destroy environment (will prompt)"
	@echo "  fmt              Format all .tf files"
	@echo "  docs             Generate module documentation (requires terraform-docs)"
	@echo ""

# ── Global ────────────────────────────────────
global-init:
	@echo "==> Initialising global state..."
	@cd global && terraform init

global-plan:
	@echo "==> Planning global resources..."
	@cd global && terraform plan -var-file="$(TFVARS_FILE)" -out=global.tfplan

global-apply:
	@echo "==> Applying global resources..."
	@cd global && terraform apply global.tfplan

# ── Environment ───────────────────────────────
init:
	@echo "==> Initialising $(ENV) environment..."
	@cd environments/$(ENV) && terraform init

validate:
	@echo "==> Validating $(ENV) environment..."
	@cd environments/$(ENV) && terraform validate

plan:
	@echo "==> Planning $(ENV) environment..."
	@cd environments/$(ENV) && terraform plan -var-file="$(TFVARS_FILE)" -out=$(ENV).tfplan

apply:
	@echo "==> Applying $(ENV) environment..."
	@cd environments/$(ENV) && terraform apply $(ENV).tfplan

destroy:
	@echo "==> Destroying $(ENV) environment (you will be prompted)..."
	@cd environments/$(ENV) && terraform destroy -var-file="$(TFVARS_FILE)"

# ── Utility ───────────────────────────────────
fmt:
	@echo "==> Formatting all Terraform files..."
	@terraform fmt -recursive .

docs:
	@echo "==> Generating module documentation..."
	@for dir in modules/*/; do \
		echo "  -> $$dir"; \
		terraform-docs markdown table --output-file README.md "$$dir"; \
	done

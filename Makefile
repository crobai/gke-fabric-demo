.PHONY: platform-up platform-plan guardrails-up guardrails-plan tenant-deploy help

help:
	@echo "make platform-up      # plane 1 — cluster + fleet (repo root)"
	@echo "make guardrails-up    # plane 2 — namespaces + guardrails (SRE/tech lead)"
	@echo "make tenant-deploy    # plane 3 — app deploy (Phase D — not ready)"

platform-plan:
	terraform init -input=false
	terraform plan -input=false

platform-up:
	terraform init -input=false
	terraform apply -input=false

guardrails-plan:
	cd tenant-guardrails && terraform init -input=false && terraform plan -input=false

guardrails-up:
	cd tenant-guardrails && terraform init -input=false && terraform apply -input=false

tenant-deploy:
	@echo "Phase D not implemented yet. See tenant-apps/README.md and DEVELOPMENT_PLAN.md"
	@exit 1

.PHONY: platform-up platform-plan guardrails-up guardrails-plan \
	tenant-deploy tenant-deploy-all tenant-logs tenant-can-i help

TENANT ?= t1-front
IMAGE  ?= python:3.12-alpine
AS     ?=

ifeq ($(TENANT),t1-front)
  APP_NAME := front
  ifeq ($(origin REPLICAS),undefined)
    REPLICAS := 2
  endif
  TARGETS_ALLOW := http://back.t2-back.svc:8080/health
  TARGETS_DENY  := http://db.t3-db.svc:8080/health
else ifeq ($(TENANT),t2-back)
  APP_NAME := back
  ifeq ($(origin REPLICAS),undefined)
    REPLICAS := 1
  endif
  TARGETS_ALLOW := http://db.t3-db.svc:8080/health
  TARGETS_DENY  := http://front.t1-front.svc:8080/health
else ifeq ($(TENANT),t3-db)
  APP_NAME := db
  ifeq ($(origin REPLICAS),undefined)
    REPLICAS := 1
  endif
  TARGETS_ALLOW :=
  TARGETS_DENY  := http://front.t1-front.svc:8080/health http://back.t2-back.svc:8080/health
else
  $(error TENANT must be t1-front, t2-back, or t3-db)
endif

help:
	@echo "make platform-up                         # plane 1 — cluster + fleet"
	@echo "make guardrails-up                       # plane 2 — namespaces + guardrails"
	@echo "make tenant-deploy TENANT=t1-front       # plane 3 — deploy one app"
	@echo "make tenant-deploy-all                   # deploy db, back, front"
	@echo "make tenant-logs TENANT=t1-front         # follow ALLOW/DENY logs"
	@echo "make tenant-can-i TENANT=t2-back AS=email@x  # RBAC check as User"

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

tf_list = $(shell python3 -c 'import sys; xs=sys.argv[1].split(); print("["+",".join("\"%s\""%x for x in xs)+"]")' "$(1)")

tenant-deploy:
	cd tenant-apps && terraform init -input=false
	cd tenant-apps && terraform workspace select -or-create "$(TENANT)"
	cd tenant-apps && terraform apply -input=false -auto-approve \
		-var="tenant=$(TENANT)" \
		-var="app_name=$(APP_NAME)" \
		-var="replicas=$(REPLICAS)" \
		-var="image=$(IMAGE)" \
		-var='targets_allow=$(call tf_list,$(TARGETS_ALLOW))' \
		-var='targets_deny=$(call tf_list,$(TARGETS_DENY))'

tenant-deploy-all:
	$(MAKE) tenant-deploy TENANT=t3-db
	$(MAKE) tenant-deploy TENANT=t2-back
	$(MAKE) tenant-deploy TENANT=t1-front

tenant-logs:
	kubectl logs -n "$(TENANT)" "deploy/$(APP_NAME)" -f | grep -E 'ALLOW|DENY|FAIL|listening'

tenant-can-i:
	@test -n "$(AS)" || (echo "Usage: make tenant-can-i TENANT=t2-back AS=roberto.comsa@esolutions.ro"; exit 1)
	kubectl auth can-i create deployments -n "$(TENANT)" --as="$(AS)"

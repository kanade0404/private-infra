GCLOUD = docker compose run --rm gcloud
TERRAFORM = docker compose run --rm terraform
TFLINT  = docker compose run --rm tflint
setup:
	$(GCLOUD) auth application-default login
	$(GCLOUD) auth login
	make project-set
	make init
init:
	$(TERRAFORM) init
format:
	$(TERRAFORM) fmt -recursive
	$(TFLINT)
	$(TERRAFORM) validate
plan:
	$(TERRAFORM) plan
apply:
	$(TERRAFORM) apply
project-set:
	$(GCLOUD) config set project kanade0404
project-list:
	$(GCLOUD) config list

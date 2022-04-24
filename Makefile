setup:
	docker compose exec tfgcloud gcloud auth application-default login
	docker compose exec tfgcloud gcloud auth login
	make project-set
	make login
	make init
init:
	docker compose exec tfgcloud terraform init
login:
	docker compose exec tfgcloud terraform login
upgrade:
	docker compose exec tfgcloud terraform init -upgrade
format:
	docker compose exec tfgcloud terraform fmt -recursive
	docker compose exec tfgcloud terraform validate
check:
	docker compose exec tfgcloud tflint
	docker compose exec tfgcloud tfsec .
plan:
	docker compose exec tfgcloud terraform plan
apply:
	docker compose exec tfgcloud terraform apply
project-set:
	docker compose exec tfgcloud gcloud config set project kanade0404
project-list:
	docker compose exec tfgcloud gcloud config list
build:
	docker compose build
up:
	docker compose up -d
stop:
	docker compose stop
ps:
	docker compose ps
exec:
	docker compose exec tfgcloud bash

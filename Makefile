setup:
	docker compose exec private_infra gcloud auth application-default login
	docker compose exec private_infra gcloud auth login
	make project-set
	make login
	make init
init:
	docker compose exec private_infra terraform init
login:
	docker compose exec private_infra terraform login
upgrade:
	docker compose exec private_infra terraform init -upgrade
format:
	docker compose exec private_infra terraform fmt -recursive
	docker compose exec private_infra terraform validate
check:
	docker compose exec private_infra tflint
	docker compose exec private_infra tfsec .
plan:
	docker compose exec private_infra terraform plan
apply:
	docker compose exec private_infra terraform apply
project-set:
	docker compose exec private_infra gcloud config set project kanade0404
project-list:
	docker compose exec private_infra gcloud config list
build:
	docker compose build
up:
	docker compose up -d
stop:
	docker compose stop
ps:
	docker compose ps
down:
	docker compose down
bash:
	docker compose exec private_infra bash

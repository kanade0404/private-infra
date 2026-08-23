up:
	docker compose up -d
stop:
	docker compose stop
ps:
	docker compose ps
down:
	docker compose down
bash:
	docker compose exec grafana_infra sh
login:
	docker compose exec grafana_infra terraform login
init:
	docker compose exec grafana_infra terraform init
format:
	docker compose exec grafana_infra terraform fmt -recursive
	docker compose exec grafana_infra terraform validate
plan:
	docker compose exec grafana_infra terraform plan
apply:
	docker compose exec grafana_infra terraform apply

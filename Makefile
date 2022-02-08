GCLOUD = docker run --rm -ti --volumes-from gcloud-kanade0404 google/cloud-sdk gcloud
setup:
	docker run -ti --name gcloud-kanade0404 google/cloud-sdk gcloud auth login
	$(GCLOUD) config set project kanade0404
format:
	terraform fmt -recursive
	docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint
	terraform validate
plan:
	terraform plan
apply:
	terraform apply
project-set:
	$(GCLOUD) config set project kanade0404
project-list:
	$(GCLOUD) config list

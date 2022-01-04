format:
	terraform fmt -recursive
	docker run --rm -v $(pwd):/data -t ghcr.io/terraform-linters/tflint
	terraform validate
plan:
	terraform plan
apply:
	terraform apply

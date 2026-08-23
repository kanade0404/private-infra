.PHONY: init format plan apply

init:
	tofu init
format: init
	tofu fmt -recursive
	tofu validate
plan:
	tofu plan
apply:
	tofu apply

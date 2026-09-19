.PHONY: init format plan apply

init:
	tofu init
format: init
	tofu fmt -recursive
	tofu validate
plan: init
	tofu plan
apply: init
	tofu apply

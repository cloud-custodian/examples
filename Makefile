# See repo README for more details on Makefile targets

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[95m%-30s\033[0m %s\n", $$1, $$2}'

install-local: ## Use Poetry to install dependencies to use this repo locally
	source helpers/setup.sh && install

install-cloudshell: ## Use Poetry and Yum to install dependencies to use this repo in AWS CloudShell
	source helpers/setup.sh && aws_cloudshell_install
	source helpers/setup.sh && install

demo-infra-provision: ## Use Terraform to provision demo infrastructure
	source helpers/setup.sh && demo_infra_provision

demo-infra-destroy: ## Use Terraform and c7n mugc to destroy any infrastructure created for demo purposes
	source helpers/setup.sh && demo_infra_destroy

custodian-run-commands-help: ## Print out the Cloud Custodian commands to run policies
# This target is intended to help remind you of the Cloud Custodian commands you need
	@echo
	@echo "to run my-first-policy-pull : custodian run resources/example-policies/my-first-policy-pull.yml -s resources/example-policies/policy-execution-output"
	@echo
	@echo "to run my-first-policy-event: custodian run resources/example-policies/my-first-policy-event.yml -s resources/example-policies/policy-execution-output"
	@echo

describe-ec2s: ## Use AWS CLI to output a table of all EC2 instances tagged `c7n-101`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws ec2 describe-instances --filters "Name=tag-key,Values=c7n-101" --query 'Reservations[*].Instances[*].{Instance:InstanceId,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value,State:State.Name}' --output table

describe-lambdas: ## Use AWS CLI to output a table of all lambda instances with the name `custodian-my-first-policy-event-stop-tagged-ec2`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws lambda list-functions --query 'Functions[?FunctionName==`custodian-my-first-policy-event-stop-tagged-ec2`].{Name:FunctionName}' --output table

describe-roles: ## Use AWS CLI to output a table of all roles with the name `c7n-101-lambda-role`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws iam get-role --role-name c7n-101-lambda-role --query 'Role.{Name:RoleName,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value}' --output table

describe-all-resources: ## Use AWS CLI to output a table of all resources tagged `c7n-101`
# This target is intended to check for any instances missed by `make demo-infra-destroy`
# This target will output account numbers, so please use with caution
	source helpers/setup.sh && describe_all_resources 

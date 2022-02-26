# See repo README for more details on Makefile targets

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[95m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Use Poetry to install dependencies to use this repo locally
	source helpers/setup.sh && install

install-cloudshell: ## Use Poetry and Yum to install dependencies to use this repo in AWS CloudShell
	source helpers/setup.sh && aws_cloudshell_install
	make install

101-infra-provision: ## Use Terraform to provision demo infrastructure
	source helpers/setup.sh && demo_infra_provision c7n-101

101-infra-destroy: ## Use Terraform and c7n mugc to destroy any infrastructure created for demo purposes
	source helpers/setup.sh && demo_infra_destroy c7n-101

describe-ec2s: ## Use AWS CLI to output a table of all EC2 instances tagged `c7n-101`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	source helpers/setup.sh && describe_ec2s	

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

workshop-infra-provision: ## Use Terraform to provision workshop demo infrastructure
	source helpers/setup.sh && demo_infra_provision c7n-workshop

workshop-infra-destroy: ## Use Terraform and c7n mugc to destroy workshop demo infrastructure
	source helpers/setup.sh && demo_infra_destroy c7n-workshop

describe-sqs: ## 
	source helpers/setup.sh && describe_sqs

stop-instance: ## Specify an EC2 instance to stop
	source helpers/setup.sh && stop_instance

start-instance: ## Specify an EC2 instance to start
	source helpers/setup.sh && stop_instance

describe-tags: ## Specify an EC2 to view tags for
	source helpers/setup.sh && describe_tags
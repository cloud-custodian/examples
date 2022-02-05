# See repo README for more details on Makefile targets

make install:
# Install dependencies
	python3 -m venv venv
	. venv/bin/activate
	@echo
	@echo "\033[95mInstalling dependencies . . .\033[0m"
	@echo
	pip install -r requirements.txt
	@echo
	@echo "\033[95mInstalling c7n project . . .\033[0m"
	@echo
	pip install -e git+https://github.com/cloud-custodian/cloud-custodian.git#egg=c7n
		@echo
	@echo "\033[95mAll done!\033[0m"
	@echo

demo-infra-provision:
# Use Terraform to provision demo infrastructure
	source helpers/setup.sh && demo_infra_provision

demo-infra-destroy:
# Use Terraform and c7n mugc to destroy any infrastructure created for demo purposes
	source helpers/setup.sh && demo_infra_destroy

custodian-run-commands-help:
# Print out the Cloud Custodian commands to run policies
# This target is intended to help remind you of the Cloud Custodian commands you need
	@echo
	@echo "to run my-first-policy-pull : custodian run resources/example-policies/my-first-policy-pull.yml -s resources/example-policies/policy-execution-output"
	@echo
	@echo "to run my-first-policy-event: custodian run resources/example-policies/my-first-policy-event.yml -s resources/example-policies/policy-execution-output"
	@echo

describe-ec2s:
# Use AWS CLI to output a table of all EC2 instances tagged `c7n-101`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws ec2 describe-instances --filters "Name=tag-key,Values=c7n-101" --query 'Reservations[*].Instances[*].{Instance:InstanceId,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value,State:State.Name}' --output table

describe-lambdas:
# Use AWS CLI to output a table of all lambda instances with the name `custodian-my-first-policy-event-stop-tagged-ec2`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws lambda list-functions --query 'Functions[?FunctionName==`custodian-my-first-policy-event-stop-tagged-ec2`].{Name:FunctionName}' --output table

describe-roles:
# Use AWS CLI to output a table of all roles with the name `c7n-101-lambda-role`
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws iam get-role --role-name c7n-101-lambda-role --query 'Role.{Name:RoleName,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value}' --output table

describe-all-resources:
# Use AWS CLI to output a table of all resources tagged `c7n-101`
# This target is intended to check for any instances missed by `make demo-infra-destroy`
# This target will output account numbers, so please use with caution
	source helpers/setup.sh && describe_all_resources 
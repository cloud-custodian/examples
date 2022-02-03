demo-infra-provision:
# Use Terraform to provision demo infrastructure
# Also replaces any instance of `{your_account_id}` in policy files so they can execute
	@echo

	echo -e "\e[35mRunning terraform plan . . ."
	@echo
	terraform -chdir=resources/example-policies-infrastructure apply

demo-infra-destroy:
# Use a Cloud Custodian policy to delete demo infrastructure tagged `c7n-101`
# Also restores files changed by `make inject-account-id` so account ID is not accidentally committed anywhere
	@echo 
	@echo "Running terraform plan . . ."
	@echo
	terraform -chdir=resources/example-policies-infrastructure plan -out=destroy-plan -destroy
	@echo 
	@echo "Type 'yes' to proceed with terraform plan: "
	@read user_input
	@echo "you wrote $(user_input)"

describe-ec2s:
# Use AWS CLI to output a table of all EC2 instances tagged `c7n-101`
# `make demo-infra-provision` provisions EC2 instances and tags them `c7n-101` 
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws ec2 describe-instances --filters "Name=tag-key,Values=c7n-101" --query 'Reservations[*].Instances[*].{Instance:InstanceId,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value,State:State.Name}' --output table

describe-lambdas:
# Use AWS CLI to output a table of all lambda instances with the name `custodian-my-first-policy-event-stop-tagged-ec2`
# The `my-first-policy-event` policy provisions a lambda instance named `custodian-my-first-policy-event-stop-tagged-ec2` and tags it `c7n-101` 
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws lambda list-functions --query 'Functions[?FunctionName==`custodian-my-first-policy-event-stop-tagged-ec2`].{Name:FunctionName}' --output table

describe-roles:
# Use AWS CLI to output a table of all roles with the name `c7n-101-lambda-role`
# `make demo-infra-provision` provisions a role with the name `c7n-101-lambda-role` and tags it `c7n-101`  
# This target is intended for demo purposes _and_ to check for any instances missed by `make demo-infra-destroy`
	aws iam get-role --role-name c7n-101-lambda-role --query 'Role.{Name:RoleName,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value}' --output table

describe-all-resources:
# Use AWS CLI to output a table of all resources tagged `c7n-101`
# This target is intended to check for any instances missed by `make demo-infra-destroy`
# This target will output account numbers, so please use with caution
	aws resourcegroupstaggingapi get-resources --tag-filters Key=c7n-101 --query 'ResourceTagMappingList[*].{ARN: ResourceARN,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value}' --output table

custodian-run-commands-help:
# Print out the Cloud Custodian commands to run policies
# This target is intended to help remind you of the Cloud Custodian commands you need
	@echo
	@echo "to run my-first-policy-pull : custodian run resources/example-policies/my-first-policy-pull.yml -s resources/example-policies/policy-execution-output"
	@echo
	@echo "to run my-first-policy-event: custodian run resources/example-policies/my-first-policy-event.yml -s resources/example-policies/policy-execution-output"
	@echo
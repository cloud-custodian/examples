#!/bin/bash

# vim: set softtabstop=4 shiftwidth=4 expandtab:

# Text color variables
PURPLE_BOLD=$'\e[1;95m'
PURPLE_REGULAR=$'\e[0;95m'
RESET_TEXT=$'\e[0;0m'

WEBINAR_TAGS="{c7n-101, c7n-workshop, c7n-102}"
QUEUE_NAMES="{c7n-workshop-queue, c7n-102-mailer-queue}"
ROLE_NAMES="{c7n-101-lambda-iam-role, c7n-workshop-lambda-iam-role, c7n-102-exeuction-role}"
PROFILE_NAMES="{source, destination}"

ECHO_TEXT="Querying AWS\n.\n. .\n. . ."

# Installation
function install () {
    echo
	echo "${PURPLE_REGULAR}Installing dependencies . . .${RESET_TEXT}"
	echo
	poetry install
    echo
	echo "${PURPLE_BOLD}Installation complete. Use ${PURPLE_BOLD}'poetry shell'${PURPLE_BOLD} to activate a virtual environment.${RESET_TEXT}"
	echo
}

function aws_cloudshell_install () {
    echo
    echo "${PURPLE_REGULAR}Installing dependencies for AWS CloudShell. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details."
    echo
    curl -sSL https://install.python-poetry.org | python3 - # Install Poetry
    sudo yum install -y yum-utils # Install yum-utils so Terraform can be installed
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo 
    sudo yum -y install terraform
    sudo amazon-linux-extras install epel -y # Install extras for things like tab completion, etc
    sudo yum install bash-completion-extras -y
    echo
    echo "${PURPLE_REGULAR}Installation complete.${RESET_TEXT}"
    echo
}

function configure_terraform_cache () {
    # Cache Terraform provider files in a common directory, so we
    # avoid repeat downloads when provisioning multiple sets of
    # resources.

    if [[ "$USER" == "cloudshell-user" ]]; then
        # Persistent storage in an AWS CloudShell environment is
        # limited to 1GB. Keep the Terraform cache in an ephemeral
        # directory that won't contribute to that limit.
        export TF_PLUGIN_CACHE_DIR="/tmp/terraform-plugin-cache"
    else
        export TF_PLUGIN_CACHE_DIR="$(pwd)/.terraform-plugin-cache"
    fi

    mkdir -p "$TF_PLUGIN_CACHE_DIR"
}


# Demo infrastructure
function demo_infra_provision () {
    configure_terraform_cache
    project="$1"    
    if [ -z "$project" ]; then
        echo "Must specify 1 argument as the directory in resources/example-policies-infrastructure/"
        exit 1
    fi
    
    if [ ! -d resources/example-policies-infrastructure/$project ]; then
        echo "$project is not a valid example policy infrastructure"
        exit 1
    fi

    echo
    echo "${PURPLE_REGULAR}Running terraform apply. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    terraform -chdir=resources/example-policies-infrastructure/${1} init
    terraform -chdir=resources/example-policies-infrastructure/${1} apply
    echo
    echo "${PURPLE_REGULAR}Provisioning complete.${RESET_TEXT}"
    echo
}

function mugc_run () {
    if [ "${1}" ]; then
        directory="$1"
    else
        echo
        read -p "${PURPLE_REGULAR}Enter directory to look for Lambdas to destroy. Options are ${WEBINAR_TAGS}: " input
        directory="$input"
    fi

    echo "${PURPLE_REGULAR}Running tools.ops.mugc ${PURPLE_BOLD}with dryrun flag${PURPLE_REGULAR}. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    poetry run python helpers/mugc.py resources/example-policies/"${directory}"/*.yml --present --dryrun
    output=$(poetry run python helpers/mugc.py resources/example-policies/"${directory}"/*.yml --present --dryrun 2>&1)

    if [ "${output}" ]; then
        echo
        read -p "${PURPLE_REGULAR}Type ${PURPLE_BOLD}'yes' ${PURPLE_REGULAR}to proceed with mugc run. " answer
        if [ "${answer}" = 'yes' ]; then
            echo
            echo "${PURPLE_REGULAR}Running tools.ops.mugc. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
            echo
            poetry run python helpers/mugc.py resources/example-policies/"${directory}"/*.yml --present
        else
            echo
            echo "User input: ${answer}. Skipping.${RESET_TEXT}"
            echo
        fi
        else
            echo
            echo "${PURPLE_REGULAR}No Custodian created lambdas found to destroy. Skipping.${RESET_TEXT}"
            echo
        fi
}

function demo_infra_destroy () {
    configure_terraform_cache

    echo
    echo "${PURPLE_REGULAR}Running terraform destroy. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details."
    echo
    terraform -chdir=resources/example-policies-infrastructure/${1} destroy
    echo
    mugc_run ${1}
    echo
    echo "${PURPLE_REGULAR}Destruction complete.${RESET_TEXT}"
    echo
}


# AWS CLI wrapper functions
function stop_instance () {
    read -p "${PURPLE_REGULAR}Enter an instance ID to stop: " answer
    echo $ECHO_TEXT
    echo aws ec2 stop-instances --instance-ids ${answer}
    aws ec2 stop-instances --instance-ids ${answer}
}

function start_instance () {
    read -p "${PURPLE_REGULAR}Enter an instance ID to start: " answer
    echo $ECHO_TEXT
    echo aws ec2 start-instances --instance-ids ${answer}
    aws ec2 start-instances --instance-ids ${answer}
}

function update_security_group () {
    read -p "${PURPLE_REGULAR}Enter group ID to update: " answer
    echo $ECHO_TEXT
    echo aws ec2 authorize-security-group-egress --group-id ${answer} --ip-permissions IpProtocol=-1,FromPort=0,ToPort=0,IpRanges=[{CidrIp=0.0.0.0/0}]
    aws ec2 authorize-security-group-egress --group-id ${answer} --ip-permissions IpProtocol=-1,FromPort=0,ToPort=0,IpRanges=[{CidrIp=0.0.0.0/0}]
}

function delete_security_group () {
    read -p "${PURPLE_REGULAR}Enter group ID to delete: " group_id
    read -p "${PURPLE_REGULAR}Enter account profile if not default: " account
    read -p "${PURPLE_REGULAR}This will permanently delete Security Group ${group_id}. This action cannot be reversed. Type 'yes' to proceed with deletion. " answer 
    echo

    if [ "${answer}" = "yes" ]; then
        if [ "$account" ]; then
            echo "${PURPLE_REGULAR}Deleting Security Group: ${group_id}."
            echo $ECHO_TEXT
            echo aws ec2 delete-security-group --group-id ${group_id} --profile ${account}
            aws ec2 delete-security-group --group-id ${group_id} --profile ${account}
        else
            echo $ECHO_TEXT
            echo aws ec2 delete-security-group --group-id ${group_id}
            aws ec2 delete-security-group --group-id ${group_id}
            ${RESET_TEXT}
        fi
    else
        echo "User input: ${answer}. Skipping.${RESET_TEXT}"
    fi 
}

function delete_queue () {
    read -p "${PURPLE_REGULAR}Enter a queue name to delete. Options are ${QUEUE_NAMES}: " queue_name
    read -p "${PURPLE_REGULAR}This will permanently delete Queue ${queue_name}. This action cannot be reversed. Type 'yes' to proceed with deletion. " answer 
    echo

    if [ "${answer}" = "yes" ]; then
        echo "${PURPLE_REGULAR}Deleting Queue: ${queue_name}.${RESET_TEXT}"
        queue_url=$(aws sqs get-queue-url --queue-name ${queue_name} --query 'QueueUrl' 2>&1)
        queue_url="${queue_url%\"}"
        queue_url="${queue_url#\"}"
        echo $ECHO_TEXT
        echo aws sqs delete-queue --queue-url ${queue_name}  
        aws sqs delete-queue --queue-url ${queue_url}
    else
        echo "User input: ${answer}. Skipping.${RESET_TEXT}"
    fi
}

function describe_all_resources () {
    echo
    read -p "${PURPLE_REGULAR}Note! Running this will ${PURPLE_BOLD}display account numbers${PURPLE_REGULAR}. Type 'yes' to proceed. " answer
    
    if [ "${answer}" = "yes" ]; then
        read -p "${PURPLE_REGULAR}Enter a tag to view all resources for. Options are ${WEBINAR_TAGS}: " answer
        echo $ECHO_TEXT
        echo aws resourcegroupstaggingapi get-resources --tag-filters Key=${answer} --query 'ResourceTagMappingList[*].{ARN: ResourceARN,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value}' --output table
        aws resourcegroupstaggingapi get-resources --tag-filters Key=${answer} --query 'ResourceTagMappingList[*].{ARN: ResourceARN,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value}' --output table
    else
        echo "User input: ${answer}. Skipping.${RESET_TEXT}"
    fi 
}

function describe_ec2_instances () {
    read -p "${PURPLE_REGULAR}Enter a tag to filter by. Options are ${WEBINAR_TAGS}: " answer
    echo $ECHO_TEXT
    echo aws ec2 describe-instances --filters "Name=tag-key,Values=$answer" --query 'Reservations[*].Instances[*].{Instance:InstanceId,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value,State:State.Name}' --output table 
    aws ec2 describe-instances --filters "Name=tag-key,Values=$answer" --query 'Reservations[*].Instances[*].{Instance:InstanceId,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value,State:State.Name}' --output table
}

function describe_lambdas () {
    echo $ECHO_TEXT
    echo aws lambda list-functions --query 'Functions[?contains(FunctionName, `custodian`) == `true`].{Name:FunctionName}' --output table
    aws lambda list-functions --query 'Functions[?contains(FunctionName, `custodian`) == `true`].{Name:FunctionName}' --output table
}

function describe_roles () {
    read -p "${PURPLE_REGULAR}Enter a role name to view. Options are {c7n-101-lambda-role, c7n-workshop-lambda-role}: " answer
    echo
    aws iam get-role --role-name ${answer} --query 'Role.{Name:RoleName,Tags:Tags[*]}' --output table
}

function describe_security_groups () {
    read -p "${PURPLE_REGULAR}Enter a tag to filter by. Options are {c7n-101, c7n-workshop}: " answer
    echo
    aws ec2 describe-security-groups --filters Name=tag-key,Values=${answer} --query 'SecurityGroups[*].{groupID:GroupId,GroupName:GroupName,ipRanges:IpPermissions[0].IpRanges[0].CidrIp,ipV6Ranges:IpPermissions[0].Ipv6Ranges[0].CidrIpv6,Tags:Tags[*]}' --output table
}

function describe_queue () {
    read -p "${PURPLE_REGULAR}Enter a queue name to view. Options are ${QUEUE_NAMES}: " answer
    queue_url=$(aws sqs get-queue-url --queue-name ${answer} --query 'QueueUrl' 2>&1)
    queue_url="${queue_url%\"}"
    queue_url="${queue_url#\"}"
    read -p "${PURPLE_REGULAR}Enter an account to view queue in (optional): " account
    echo $ECHO_TEXT
    if [ "$account" ]; then
        echo aws sqs get-queue-url --queue-name ${answer} --query 'QueueUrl' 
        echo aws sqs list-queue-tags --queue-url ${answer} --output table --profile ${account}
        aws sqs list-queue-tags --queue-url ${queue_url} --output table --profile ${account}
        aws_command=$(aws sqs get-queue-attributes --queue-url ${queue_url} --attribute-names KmsMasterKeyId --output table --profile ${account})
        if [ -z "$aws_command" ]; then
            echo
            echo "No KmsMasterKeyId found for this queue."
            echo
        else
            echo "$aws_command"
        fi
    else
        echo aws sqs get-queue-url --queue-name ${answer} --query 'QueueUrl'
        echo aws sqs list-queue-tags --queue-url ${answer} --output table
        aws sqs list-queue-tags --queue-url ${queue_url} --output table
        aws_command=$(aws sqs get-queue-attributes --queue-url ${queue_url} --attribute-names KmsMasterKeyId --output table)
        if [ -z "$aws_command" ]; then
            echo
            echo "No KmsMasterKeyId found for this queue."
            echo
        else
            echo "$aws_command"
        fi
    fi
}

function describe_roles () {
    read -p "${PURPLE_REGULAR}Enter a role name to view. Options are ${ROLE_NAMES}: " answer
    echo $ECHO_TEXT
    echo aws iam get-role --role-name ${answer} --query 'Role.{Name:RoleName,Tags:Tags[*]}' --output table
    aws iam get-role --role-name ${answer} --query 'Role.{Name:RoleName,Tags:Tags[*]}' --output table
}

function describe_s3_buckets () {
    read -p "${PURPLE_REGULAR}Enter a tag to view all buckets for for. Options are ${WEBINAR_TAGS}: " answer
    read -p "${PURPLE_REGULAR}Enter an account to view buckets in (optional): " account
    echo $ECHO_TEXT

    if [ "$account" ]; then
        echo aws resourcegroupstaggingapi get-resources --tag-filters Key=${answer} --resource-type-filters s3:bucket --query 'ResourceTagMappingList[*].{Account:`'${account}'`,ARN: ResourceARN,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value}' --output table --profile ${account}
        aws resourcegroupstaggingapi get-resources --tag-filters Key=${answer} --resource-type-filters s3:bucket --query 'ResourceTagMappingList[*].{Account:`'${account}'`,ARN: ResourceARN,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value}' --output table --profile ${account}
    else
        echo aws resourcegroupstaggingapi get-resources --tag-filters Key=${answer} --resource-type-filters s3:bucket --query 'ResourceTagMappingList[*].{Account:`'${account}'`,ARN: ResourceARN,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value}' --output table
        aws resourcegroupstaggingapi get-resources --tag-filters Key=${answer} --resource-type-filters s3:bucket --query 'ResourceTagMappingList[*].{Account:`'${account}'`,ARN: ResourceARN,tagKey:Tags[?Key==`'${answer}'`]|[0].Key,tagValue:Tags[?Key==`'${answer}'`]|[0].Value}' --output table
    fi
}

function describe_security_groups () {
    read -p "${PURPLE_REGULAR}Enter a tag to filter by. Options are ${WEBINAR_TAGS}: " answer
    read -p "${PURPLE_REGULAR}Enter an account to view security groups in (optional): " account
    echo $ECHO_TEXT
    
    if [ "$account" ]; then
        echo aws ec2 describe-security-groups --filters Name=tag-key,Values=${answer} --query 'SecurityGroups[*].{Account:`'${account}'`,groupID:GroupId,GroupName:GroupName,ipRanges:IpPermissions[0].IpRanges[0].CidrIp,ipV6Ranges:IpPermissions[0].Ipv6Ranges[0].CidrIpv6,Tags:Tags[*]}' --output table --profile ${account}
        aws ec2 describe-security-groups --filters Name=tag-key,Values=${answer} --query 'SecurityGroups[*].{Account:`'${account}'`,groupID:GroupId,GroupName:GroupName,ipRanges:IpPermissions[0].IpRanges[0].CidrIp,ipV6Ranges:IpPermissions[0].Ipv6Ranges[0].CidrIpv6,Tags:Tags[*]}' --output table --profile ${account}
    else
        echo aws ec2 describe-security-groups --filters Name=tag-key,Values=${answer} --query 'SecurityGroups[*].{Account:`'${account}'`,groupID:GroupId,GroupName:GroupName,ipRanges:IpPermissions[0].IpRanges[0].CidrIp,ipV6Ranges:IpPermissions[0].Ipv6Ranges[0].CidrIpv6,Tags:Tags[*]}' --output table
        aws ec2 describe-security-groups --filters Name=tag-key,Values=${answer} --query 'SecurityGroups[*].{Account:`'${account}'`,groupID:GroupId,GroupName:GroupName,ipRanges:IpPermissions[0].IpRanges[0].CidrIp,ipV6Ranges:IpPermissions[0].Ipv6Ranges[0].CidrIpv6,Tags:Tags[*]}' --output table
    fi
}

function describe_instance_tags () {
    read -p "${PURPLE_REGULAR}Enter an instance ID to view tags for: " answer
    echo $ECHO_TEXT
    echo aws ec2 describe-tags --filters "Name=resource-id,Values=${answer}" --query 'Tags[*].{ResourceID:ResourceId,ResourceType:ResourceType,tagKey:Key,tagValue:Value}' --output table
    aws ec2 describe-tags --filters "Name=resource-id,Values=${answer}" --query 'Tags[*].{ResourceID:ResourceId,ResourceType:ResourceType,tagKey:Key,tagValue:Value}' --output table
}

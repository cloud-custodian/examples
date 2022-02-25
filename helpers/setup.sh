#!/bin/bash

PURPLE_BOLD=$'\e[1;95m'
PURPLE_REGULAR=$'\e[0;95m'
RESET_TEXT=$'\e[0;0m'

function mugc_run () {
    echo
    echo "${PURPLE_REGULAR}Running tools.ops.mugc ${PURPLE_BOLD}with dryrun flag${PURPLE_REGULAR}. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    poetry run python helpers/mugc.py resources/example-policies/${1}/*.yml --present --dryrun
    output=$(poetry run python helpers/mugc.py resources/example-policies/${1}/*.yml --present --dryrun 2>&1)
    if [ "${output}" ];
        then
        echo
        read -p "${PURPLE_REGULAR}Type ${PURPLE_BOLD}'YES' ${PURPLE_REGULAR}to proceed with mugc run. " answer
        if [ "${answer}" = 'YES' ];
            then
            echo
            echo "${PURPLE_REGULAR}Running tools.ops.mugc. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
            echo
            poetry run python helpers/mugc.py resources/example-policies/${1}/*.yml --present
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

function demo_infra_provision () {
    echo
    echo "${PURPLE_REGULAR}Running terraform apply. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    terraform -chdir=resources/example-policies-infrastructure/${1} init
    terraform -chdir=resources/example-policies-infrastructure/${1} apply
    echo
    echo "${PURPLE_REGULAR}Provisioning complete.${RESET_TEXT}"
    echo
}

function describe_all_resources () {
    echo
    read -p "${PURPLE_REGULAR}Note! Running this will ${PURPLE_BOLD}display account numbers${PURPLE_REGULAR}. Type 'YES' to proceed. " answer

    if [ "${answer}" = "YES" ];
        then
        aws resourcegroupstaggingapi get-resources --tag-filters Key=c7n-101 --query 'ResourceTagMappingList[*].{ARN: ResourceARN,tagKey:Tags[?Key==`c7n-101`]|[0].Key,tagValue:Tags[?Key==`c7n-101`]|[0].Value}' --output table
    else
        echo "User input: ${answer}. Skipping.${RESET_TEXT}"
    fi 
}

function describe_sqs () {
    output=$(aws sqs get-queue-url --queue-name c7n-workshop-queue 2>&1)
    IFS=' '
    read -a strarr <<< "$output"
    aws sqs list-queue-tags --queue-url ${strarr[1]}
    
}

function install () {
    echo
	echo "${PURPLE_REGULAR}Installing dependencies . . .${RESET_TEXT}"
	echo
	poetry install
	echo "${PURPLE_REGULAR}Installation complete. Use ${PURPLE_BOLD}'poetry shell'${PURPLE_REGULAR} to activate a virtual environment.${RESET_TEXT}"
	echo
}

function aws_cloudshell_install () {
    echo
    echo "${PURPLE_REGULAR}Installing dependencies for AWS CloudShell. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details."
    echo
    curl -sSL https://install.python-poetry.org | python3 - # Install Poetry
    source $HOME/.poetry/env
    sudo yum install -y yum-utils # Install yum-utils so Terraform can be installed
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo 
    sudo yum -y install terraform
    sudo amazon-linux-extras install epel # Install extras for things like tab completion, etc
    sudo yum install bash-completion-extras
    echo
    echo "${PURPLE_REGULAR}Installation complete.${RESET_TEXT}"
    echo
}
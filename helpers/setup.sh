#!/bin/bash

PURPLE_BOLD=$'\e[1;95m'
PURPLE_REGULAR=$'\e[0;95m'
RESET_TEXT=$'\e[0;0m'

function mugc_run () {
    echo
    echo "${PURPLE_REGULAR}Running tools.ops.mugc ${PURPLE_BOLD}with dryrun flag${PURPLE_REGULAR}. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    poetry run python helpers/mugc.py resources/example-policies/*.yml --present --dryrun
    output=$(poetry run python helpers/mugc.py resources/example-policies/*.yml --present --dryrun 2>&1)
    if [ "${output}" ];
        then
        echo
        read -p "${PURPLE_REGULAR}Type ${PURPLE_BOLD}'YES' ${PURPLE_REGULAR}to proceed with mugc run. " answer
        if [ "${answer}" = 'YES' ];
            then
            echo
            echo "${PURPLE_REGULAR}Running tools.ops.mugc. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
            echo
            poetry run python helpers/mugc.py resources/example-policies/*.yml --present
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
    terraform -chdir=resources/example-policies-infrastructure destroy
    echo
    mugc_run
    echo
    echo "${PURPLE_REGULAR}Destruction complete.${RESET_TEXT}"
    echo
}

function demo_infra_provision () {
    echo
    echo "${PURPLE_REGULAR}Running terraform apply. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    terraform -chdir=resources/example-policies-infrastructure init
    terraform -chdir=resources/example-policies-infrastructure apply
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

function local_install () {
    echo
	echo "${PURPLE_REGULAR}Installing dependencies . . ."
	echo
	poetry install
	echo "${PURPLE_REGULAR}Installation complete. Use 'poetry shell' to activate a virtual environment.${RESET_TEXT}"
	echo
}

function aws_cloudshell_install () {
    echo
    echo "${PURPLE_REGULAR}Installing dependencies for AWS CloudShell. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details."
    echo
    curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
    source $HOME/.poetry/env
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum -y install terraform
    echo
    echo "${PURPLE_REGULAR}Installation complete.${RESET_TEXT}"
    echo
}
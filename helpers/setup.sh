#!/bin/bash

PURPLE_BOLD=$'\e[1;35m'
PURPLE_REGULAR=$'\e[0;35m'
RESET_TEXT=$'\e[0;0m'

function mugc_run () {
    echo
    echo "${PURPLE_REGULAR}Running tools.ops.mugc ${PURPLE_BOLD}with dryrun flag${PURPLE_REGULAR}. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
    echo
    python3 -m tools.ops.mugc -c resources/example-policies/*.yml --present --dryrun
    output=$(python3 -m tools.ops.mugc -c resources/example-policies/*.yml --present --dryrun 2>&1)
    if [ "$output" ];
    then
    echo
    echo "${PURPLE_REGULAR}Type ${PURPLE_BOLD}'YES' ${PURPLE_REGULAR}to proceed with mugc run."
    read answer
        if [ "$answer" = 'YES' ];
        then
        echo
        echo "${PURPLE_REGULAR}Running tools.ops.mugc. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details.${RESET_TEXT}"
        echo
        python3 -m tools.ops.mugc -c resources/example-policies/*.yml --present
        else
        echo
        echo "User input: $answer. Skipping."
        echo
        fi
    # local answer="$input"
    else
    echo
    echo "${PURPLE_REGULAR}No Custodian created lambdas found to destroy. Skipping."
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
    echo "${PURPLE_REGULAR}Destruction complete."
    echo
}

function demo_infra_provision () {
    echo
    echo "${PURPLE_REGULAR}Running terraform apply. See repo ${PURPLE_BOLD}README ${PURPLE_REGULAR}for more details."
    echo
    terraform -chdir=resources/example-policies-infrastructure apply
    echo
    echo "${PURPLE_REGULAR}Provisioning complete."
    echo
}
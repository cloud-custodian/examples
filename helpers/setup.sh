#!/bin/bash

PURPLE=$'\e[1;35m'
echo -e "${PURPLE}Running terraform plan . . ."
echo
terraform -chdir=resources/example-policies-infrastructure plan -out=destroy-plan -destroy
echo
echo "${PURPLE}Type 'yes' to proceed with terraform plan to destroy: "
read userinput
if [ $userinput == "yes" ];
then
echo -e "${PURPLE}User input: $userinput. Running terraform destroy . . ."
terraform -chdir=resources/example-policies-infrastructure apply destroy-plan
else
echo -e "${PURPLE}User input: $userinput. Will not run terraform destroy."
fi
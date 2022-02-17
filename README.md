# c7n Examples Repository 

This directory contains resources intended to facilitate webinar instruction and first time users embarking on their c7n journey.

This directory provides example c7n policies, demo infrastructure via Terraform, and automated processes.  

```
├── Makefile : Make targets to facilitate demo infra provisioning and tear down
├── README.md : This file
├── helpers : Helper scripts
├── requirements.txt
└── resources : Example c7n policies, Terraform
    ├── example-policies : Example policies and policy execution output
    │   └── policy-execution-output : Policy execution output
    └── example-policies-infrastructure: Terraform and related infrastructure files
```

# Prerequisites

In order to use this repo, you will need:
* [AWS account](https://aws.amazon.com/) for access to AWS cloud resources and services
* [AWS CLI](https://aws.amazon.com/cli/) for command line access to your AWS account
* [Poetry](https://python-poetry.org/) for Python package and dependency management
* [Python 3.7+](https://www.python.org/) to run the code
* [Terraform](https://www.terraform.io/) to provision AWS infrastructure


# Support

Currently, this repo supports:

* [AWS](https://aws.amazon.com/)

# Makefile

The Makefile contains a set of targets that automate common processes.

`install` downloads and prepares dependencies so Terraform and policies can be executed as intended. This install assumes you already have Poetry and Terraform.

`install-cloudshell` downloads and prepares dependencies so Terraform and policies can be executed as intended within AWS [CloudShell](https://console.aws.amazon.com/cloudshell). This install includes download and installation of Poetry and Terraform as well.

`demo-infra-provision` and `demo-infra-destroy` execute bash scripts responsible for either provisioning or destroying cloud infrastructure. Cloud infrastructure is provisioned using Terraform. Terraform is also used to destroy infrastructure along with the Cloud Custodian tool, mugc.

Click [here](https://github.com/cloud-custodian/cloud-custodian/tree/master/tools/ops#mugc) for more information about [mugc](https://github.com/cloud-custodian/cloud-custodian/tree/master/tools/ops#mugc).

`custodian-run-commands-help` lists the `custodian` commands needed to run the example policies to copy and paste.

`describe-ec2s`, `describe-lambdas`, `describe-roles`, and `describe-all-resources` all use AWS CLI to query resources. *Please note that describe-all-resources displays account numbers.*

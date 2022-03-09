# Cloud Custodian Examples Repository 

This directory contains resources intended to facilitate webinar instruction and first time users embarking on their c7n journey.

This directory provides example c7n policies, demo infrastructure via Terraform, and automated processes.  

```
├── Makefile
├── README.md
├── helpers: Helper scripts
├── poetry.lock
├── pyproject.toml
├── resources: Webinar materials
│   ├── example-policies: Example policies
│   │   ├── c7n-101: Example policies for c7n 101 webinar
│   │   │   └── policy-execution-output: Policy execution output
│   │   └── c7n-workshop: Example policies for c7n workshop
│   │       └── policy-execution-output: Policy execution output
│   └── example-policies-infrastructure: Terraform for demo infrastructure
│       ├── c7n-101:  Terraform for demo infrastructure for c7n 101 webinar
│       └── c7n-workshop: Terraform for demo infrastructure for c7n workshop webinar
```

# Prerequisites

In order to use this repo, you will need:
* [AWS account](https://aws.amazon.com/) for access to AWS cloud resources and services

* [AWS CLI](https://aws.amazon.com/cli/) for command line access to your AWS account

* [Poetry](https://python-poetry.org/) for Python package and dependency management

* [Python 3.7+](https://www.python.org/) to run the code

* [Terraform](https://www.terraform.io/) to provision AWS infrastructure

* [Appropriate read and write permissions in AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_understand-policy-summary-access-level-summaries.html) to provision the infrastructure outlined in the Terraform main files

* A [default VPC](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html) is not required, however, since no VPC is specified in the Terraform main files, if your AWS account does not have a designated default VPC, you will encounter an error when provisioning infrastructure (see **Troubleshooting** below for more information)

* [AWS CloudShell](https://aws.amazon.com/cloudshell/) is not required, but strongly recommended

# Support

Currently, this repo supports:

* [AWS](https://aws.amazon.com/)

# Makefile

The Makefile contains a set of targets that automate common processes.

Use `make help` to view a list of targets and descriptions of what they do.

At a high level, these make targets can be broken down into four categories:

1. **Installation**: These targets invoke bash scripts that install binaries and dependencies to create your learning environment.

2. **Demo infrastructure support**: These targets use Terraform to provision and tear down AWS infrastructure intended for demonstration purposes.

3. **Cloud Custodian command help**: These targets print out common Cloud Custodian commands so you can easily copy and paste them.

4. **AWS CLI wrappers**: These targets invoke bash script wrappers for helpful AWS CLI operations.

# How to Use This Repo

## Setting Up Your Environment Within AWS CloudShell

Since -- at the moment -- this project supports and requires access to an AWS account, we recommend using [AWS CloudShell](https://aws.amazon.com/cloudshell/). CloudShell is a browser-based shell with AWS CLI access from the AWS Management Console. CloudShell provides 1GB of persistent storage and comes with helpful software and tools pre-installed.

1. With CloudShell loaded, clone this project into your directory of choice: `git clone https://github.com/cloud-custodian/examples.git`

2. Navigate to your new `examples` directory and use `make install-cloudshell` to download and install the binaries and dependencies you will need to run the example Cloud Custodian policies.

3. Once installation is complete, use `poetry shell` to activate a virtual environment. (Use `exit` to deactivate your virtual environment.)

4. In your virtual environment, run `custodian -h` to verify successful installation of Cloud Custodian.

## Provisioning Sandbox Infrastructure

1. Run `make 101-infra-provision` to deploy sandbox AWS infrastructure to test Cloud Custodian policies with. Please note that Terraform prompts for user input.

2. Check to make sure your infrastructure deployed correctly with `make describe-ec2s`. When prompted for a tag to filter by, use `c7n-101`. You should see output that looks something like this:

```
------------------------------------------------------------------------
|                           DescribeInstances                          |
+----------------------+----------+----------+-------------------------+
|       Instance       |  State   | tagKey   |        tagValue         |
+----------------------+----------+----------+-------------------------+
|  i-12345678912345678 |  running |  c7n-101 |                         |
|  i-23456789123456789 |  running |  c7n-101 |  my-first-policy-pull   |
|  i-34567891234567891 |  running |  c7n-101 |  my-first-policy-event  |
+----------------------+----------+----------+-------------------------+
```

## Running Cloud Custodian

1. To quickly reference which Custodian commands to use, run `make 101-custodian-commands` which will print out the most common commands for you to conveniently copy and paste.

2. Executing `custodian run resources/example-policies/c7n-101/my-first-policy-pull.yml -s resources/example-policies/c7n-101/policy-execution-output --verbose --dryrun` will run `my-first-policy-pull.yml`. Note the optional `--verbose` and `--dryrun` flags.

3. `make 101-custodian-commands` will also provide you with you `custodian report resources/example-policies/c7n-101/my-first-policy-pull.yml -s resources/example-policies/c7n-101/policy-execution-output --field tag:c7n-101=tag:c7n-101 --format grid` which prints out a report like the following. (Please note that the example below has been amended for brevity's sake.):

    ```
    +---------------------+----------------+----------------------+
    | InstanceId          | InstanceType   | tag:c7n-101          |
    +=====================+================+======================+
    | i-12345678912345678 | t2.micro       | my-first-policy-pull |
    ```
    You can use this report to verify the resources that match your policy filters before removing the `--dryrun` flag and executing the policy `filters` _and_ `actions`.

4. Use `custodian run resources/example-policies/c7n-101/my-first-policy-pull.yml -s resources/example-policies/c7n-101/policy-execution-output --verbose` to execute the policy for real.

5. Running `make describe-ec2s` again should output something like the following:

    ```
    ------------------------------------------------------------------------
    |                           DescribeInstances                          |
    +----------------------+----------+----------+-------------------------+
    |       Instance       |  State   | tagKey   |        tagValue         |
    +----------------------+----------+----------+-------------------------+
    |  i-12345678912345678 | running  |  c7n-101 |                         |
    |  i-23456789123456789 | stopping |  c7n-101 |  it worked!             |
    |  i-34567891234567891 | running  |  c7n-101 |  my-first-policy-event  |
    +----------------------+----------+----------+-------------------------+
    ```
    
    
    Which demonstrates that the policy performed as expected: The policy queried EC2 instances and any EC2 instance that matched the filters were stopped and tagged as specified.

## Tearing Down Sandbox Infrastructure

1. Best practices recommends restoring your AWS account to its previous state. Use `make 101-infra-destroy` to remove any AWS resources or services managed by this project's Terraform or created by Custodian event policies. Please note that Terraform destroy and c7n mugc prompts for user input.

# Tips, Tricks, and Other Resources

* Use `make help` to explore the other make targets available to you. Many of the AWS CLI wrapper targets provide an easy way to view your AWS infrastructure without having to recall complex command line strings.

* Check out [cloudcustodian.io](https://cloudcustodian.io/) for more information about Cloud Custodian.

* Come ask questions on [Gitter](gitter.im/cloud-custodian) and in our [bi-weekly community meetings](https://www.youtube.com/playlist?list=PLJ2Un8H_N5uBeAAWK95SnWvm_AuNJ8q2x).

* Join [our webinars](https://app.livestorm.co/stacklet-io) to learn more.

* And subscribe to [our Google Group](https://groups.google.com/g/cloud-custodian?pli=1).

# Troubleshooting

## Error when running `make {webinar}-infra-provision`: VPCIdNotSpecified

```
Error: Error launching source instance: VPCIdNotSpecified: No default VPC for this user. GroupName is only supported for EC2-Classic and default VPC.
```

This usually happens when there is no default VPC configured for your AWS account. Some cloud resources -- like EC2 instances -- require a VPC in order to be deployed. If no VPC is configured for deployment and there is no default VPC to fall back on, then AWS cannot launch an EC2 instance. 

Your options are to either configure a default VPC for your account or to specify a VPC or subnet for the EC2 instance resources in the appropriate Terraform file.

Or you can remove the EC2 instance resources from the Terraform file completely. Doing so will render any policies concerning EC2 instances irrelevant.

Please refer to the [AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/default-vpc.html) and [Terraform instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) documentation for more information.

## Error when running `make {webinar}-infra-provision`: EntityAlreadyExists 

```
Error: failed creating IAM Role (<role-name>): EntityAlreadyExists: Role with name <role-name> already exists.
```

This usually happens when your Terraform state management becomes misaligned. Terraform is trying to create a new resource -- in this case, a a new IAM role -- but this particular IAM role already exists and even if Terraform is the one that created the role, it has somehow lost track of it. Since two roles cannot have the same name, you receive an error. 

If you run `make describe-roles` you will likely discover that you have the named role in your inventory. While this will not hinder your ability to run Cloud Custodian policies, it will interfere with `make {webinar}-infra-destroy`, potentially leaving the responsibility to you to manually delete the role once you are done with your sandbox.

Your options are to either remember to manually delete the role or to import the forgotten resource back into Terraform's state.

Please refer to the [Terraform import documentation](https://www.terraform.io/cli/import/usage) for more information.
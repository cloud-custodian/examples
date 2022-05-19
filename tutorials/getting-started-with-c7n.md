# Getting Started with Cloud Custodian

[Cloud Custodian](https://cloudcustodian.io/) – also known by its package name c7n – is a rules engine for cloud account and resource management. Cloud Custodian uses the data serialization language YAML to compose policy configuration files based on cloud resource queries, filters, and actions. Cloud Custodian is operated via a set of terminal commands.

Cloud Custodian is an open source project written in Python and part of the [Cloud Native Computing Foundation](https://www.cncf.io/) ecosystem.

This tutorial will guide you through:

1. Cloud Custodian installation and installation verification
2. Policy authorship
3. Policy execution

This tutorial assumes you have familiarity with:

* General software development practices
* [Amazon Web Services (AWS)](https://aws.amazon.com/)
* The Python programming language

This tutorial requires:

* Python 3.7+
* Access to an AWS account with read-write permissions
* The [AWS Management Console](https://aws.amazon.com/console/)
* A text editor of your choice

This tutorial does not support:

* Cloud providers other than AWS*
* Environments other than [AWS CloudShell](https://aws.amazon.com/cloudshell/)

(*While this tutorial features an AWS implementation of Cloud Custodian, be aware Cloud Custodian supports cloud providers Azure and GCP as well. Moreover, the basic concepts, syntax, and structure of Cloud Custodian policies can be applied across providers, so even if AWS is not your particular use case, this tutorial can still be a useful resource. To learn more, please refer to the [Cloud Custodian documentation](https://cloudcustodian.io/docs/index.html#).)

# Why Cloud Custodian?

## A High Level Look at the Cloud and Cloud Access Control

With the advent of public cloud providers, software developers and the enterprises they work for were freed of server management responsibilities. The management of servers became the responsibility of “the cloud.”

This cloud is accessed via public APIs. While this enables the almost-instantaneous deployment of infrastructure with a mere provider account, it also enables security vulnerabilities and exposure of sensitive data.

## Keeping the Cloud in Compliance

Policies and permissions are only effective when enforced. The ease and freedom provided by the public cloud mean a greater risk for non-compliant cloud resources and identities to slip by undetected. This introduces not only security vulnerabilities, but regulatory violations and expensive cloud waste.

In order to manage an enterprise’s cloud real estate, cloud engineers can write scripts utilizing cloud provider APIs in order to collect information about remote resources and then act upon that information. These scripts can range from event-based auto-tagging, automatically remediating noncompliant resources, and garbage collection of unused, idle, or over-provisioned instances.

Let's say we have a company policy that forbids unencrypted cloud storage instances in order to protect sensitive data. We could enforce this company policy with an ad-hoc script. An example of such a script is written in pseudocode below.

```
remove_unencrypted_storage_instances_func():
    
    unencrypted_storage_instances =
        # Make an API call to GET list of storage instances with "encryption": "false"
        http_request_func("GET",
        "cloud_api_url",
        account=account_id,
        auth_token=auth_token,
        params={"resource_type": "storage", "storage_encryption": "false"})

    """
    http_request_func returns a JSON object:
    {"items":
        [
            {"name": "storage_001",
            "account": "acount_number_5555",
            "tags": {"created_by": "user_001"}
            "encryption": "false"},
            ...
        ]
    }
    """

    # Tag each storage instance returned above
    for item in unencrypted_storage_instances:
        # Make an API call to PUT a new tag on each instance
        http_request_func("PUT",
        "cloud_api_url",
        account=account_id,
        auth_token=auth_token,
        params={"name": item["name"], "tags": {"mark_for_delete": "yes"}})
```

Using multiple API calls, the example script makes a request for all storage instances that have encryption set to false, tags these instances, and then deletes the tagged instances. The script can be used in conjunction with a cron-job configured to run it on a schedule. This way we ensure we are regularly checking for and remediating non-compliant resources.

This script will work well in a limited cloud infrastructure where there are few resources to manage, but what happens to these scripts when your cloud begins to grow? How will you manage these scripts and how will you ensure they are thoroughly tested and reliable? How will you keep up with expanding cloud products? Who will maintain these scripts, and -- most importantly -- how will these scripts generate insights and auditing data?

## Enter Cloud Custodian

It is not difficult to imagine such a collection of scripts quickly growing unwieldy, diverting engineering resources away from product development and weakening policy enforcement. Cloud Custodian restores the craft of innovation to engineers and restores the promise of freedom and flexibility to the cloud. 

# What is Cloud Custodian?

## Governance as Code

Embracing the principles of software versioning, declarative programming languages, and mechanisms of automation, Cloud Custodian synthesizes public cloud policy authorship into a cloud specific language implemented with a YAML configuration file. A Cloud Custodian YAML configuration file condenses ad-hoc policy scripts into structure and syntax. Because of this, Cloud Custodian is more than just a tool. Cloud Custodian enables empowerment and collaboration.

In other words, Cloud Custodian makes it easy to erect guardrails that help keep everyone on track.

Cloud Custodian is also a CNCF Sandbox project in production at and contributed to by a legion of notable companies. The project supports Amazon Web Services, Microsoft Azure, and Google Cloud Provider with alpha support for Kubernetes and OpenStack.

At a high level, Cloud Custodian integrates seamlessly with services, features, and resources native to AWS, Azure, and GCP. Cloud Custodian’s basic syntax of resources, filters, and actions abstracts away the API calls, business logic, and data translation of cloud policy authorship.

## Resources, Filters, and Actions

Policy configuration files lie at the heart of Cloud Custodian. These policies dictate how Cloud Custodian engages with the SDKs of the cloud providers it supports.

With Cloud Custodian, the example ad-hoc script from before becomes the simplified, standardized, and easier-to-version YAML configuration file below.

```
policies:
  # List S3 buckets that are not encrypted
  - name: tutorial-policy-lambda-test
    resource: aws.s3
    description: |
      Lists all S3 Buckets instances that are not encrypted.
    mode:
      type: cloudtrail
      role: arn:aws:iam::162270148078:role/test-event-mode-role-01
      events:
        - CreateBucket
    filters:
      - type: bucket-encryption
        state: False
    actions:
      - type: tag
        tags:
          "not-encrypted": " "
```

# Using Cloud Custodian

## Installing Cloud Custodian

Since this tutorial assumes you have familiarity with and access to an AWS account, we recommend using [AWS CloudShell](https://aws.amazon.com/cloudshell/). CloudShell is a browser-based shell with AWS CLI access from the AWS Management Console. CloudShell provides 1GB of persistent storage and comes with helpful software and tools pre-installed.

To install Cloud Custodian in CloudShell, perform the following:

1. Create a virtual environment by running `python3 -m venv c7n-tutorial`.
2. Activate the virtual environment with `source c7n-tutorial/bin/activate`. Once activated, your command line should be prefixed with `(c7n-tutorial)`.
3. Now run `pip3 install c7n`.
4. To verify your installation, run `custodian -h` and you should receive an output of available `custodian` commands as a result.

## AWS Sandbox Infrastructure

For this tutorial, you will want to provision some AWS infrastructure you can experiment with. The policy you will write and execute queries EC2 instances and filters on tags so you do not need to provision instances beyond the AWS free tier. Using the AWS Management Console, [launch two EC2 instances](https://aws.amazon.com/ec2/) and tag them as follows:

1. Tag one with the key `c7n-tutorial` and leave the value empty
2. Tag one with the key `c7n-tutorial` and with the value `my-first-policy-pull` 

## Anatomy of a Cloud Custodian Policy

As mentioned and illustrated above, Cloud Custodian synthesizes the many ad-hoc scripts you would need to write to orchestrate API calls to a cloud provider in order to govern your infrastructure into a domain specific language. This language uses a declarative vocabulary of `resource`, `filters`, and `actions` to configure policies in YAML. This vocabulary is explained more below:

YAML Key | Description
--- | ---
resource | A cloud resource or service. In a Cloud Custodian policy file, this key refers to the type of cloud resource or service the following `actions` and `filters` values will act upon. Run `custodian schema` to reveal a list of resources available to Cloud Custodian.
filters | Attributes of a resource that can be used as criteria to filter resources by. The result of a filter is an output of resources that meet the filter criteria. This output is what `actions` will act upon. At their core, `filters` are key value pairs that can be used more generically as well. See the [Cloud Custodian documentation](https://cloudcustodian.io/docs/filters.html) for more information. Run `custodian schema ec2.filters` to reveal a list of filters available for EC2 instances.
actions | Operations that can be performed upon a resource. These operations will be performed on the output of `filters`. At their core, `actions` are webhooks that can be used more generically as well. See the [Cloud Custodian documentation](https://cloudcustodian.io/docs/actions.html) for more information. Run `custodian schema ec2.actions` to reveal a list of actions available for EC2 instances.

## Your First Cloud Custodian Policy

As mentioned above, for your first policy, you will filter for EC2 instances with a specific tag key and value. When and if the policy finds any such instances, the policy will stop the instance(s) and update the tag key with a new value.

Now that you have been exposed to the anatomy of a Cloud Custodian policy, try writing one on your own. Create a file named `my-first-policy-pull.yml` and give it a try.

If you are using AWS CloudShell, the easiest way to write your policy file is to use your text editor of choice and then upload the file to CloudShell via the Actions dropdown menu available in the CloudShell UI.

If your policy looks like the one below, great job!

```
policies:
  - name: my-first-policy-pull-stop-tagged-ec2
    resource: aws.ec2
    filters:
      - tag:c7n-tutorial: "my-first-policy-pull"
    actions:
      - type: tag
        tags:
          c7n-tutorial: "it worked!"
      - stop

```

## Copy and Paste Commands

For this tutorial, you will make use of the following `custodian` commands:

**Validating Your Policy File**

Validate your policy file against the JSON schema to ensure it is correctly configured.

```
custodian validate my-first-policy-pull.yml
```

**Running Your Policy File**

Run your policy file and output any reporting generated by the policy execution to the specified directory.

In the future, you may want to specify a directory where you want Cloud Custodian to place the output of your policy executions. This output includes logging, metadata, and JSON associated with the execution. For this tutorial, you can simply direct Cloud Custodian to save this data to the immediate directory. You will notice that even with a dry run, Cloud Custodian generates a new directory named after the executed policy. 

We add the `--verbose` flag to output logging as the policy executes. In the beginning, this is helpful because it lets you observe what Cloud Custodian is doing. Later on, you may want to use it for debugging.

We add the `--dryrun` flag to perform the `filters` part of a policy without the `actions` – in other words, execute the policy without any consequences.

```
custodian run my-first-policy-pull.yml --output-dir . --verbose --dryrun
```

**Viewing Policy Execution Reports**

Display a tabular report of resources that match your policy filters.

The resources in this report are the resources that any specified `actions` will be performed on.

The `--field` argument adds an additional column to view the specific `c7n-tutorial` tag you added to the EC2 instance. You can read more about [field customization here](https://cloudcustodian.io/docs/quickstart/advanced.html?highlight=report#adding-custom-fields-to-reports).

The `--format` argument specifies how we want to view the report. In this case, we have specified a `grid` format.

```
custodian report my-first-policy-pull.yml --output-dir . --field tag:c7n-tutorial=tag:c7n-tutorial --format grid
```

**Using the AWS CLI to View Your EC2 Instances**

This is an AWS CLI operation that describes a specified instance or instances.

The `--filters` argument performs a server-side extraction of all instances that meet the specified criteria. In this case, we are filtering for instances with the tag “c7n-tutorial.”

The `--query` argument performs client-side filtering. In this case, we are using it to help reduce the output we receive down to something more useful.

The `--output` argument allows us to specify how we would like to format the data we receive. In this case, we are specifying a table.

This command will be useful to view the state of your EC2 instances before and after you execute your Cloud Custodian policy. You can use this command in CloudShell.

For more information, [refer to the AWS CLI documentation](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/describe-instances.html).

```
aws ec2 describe-instances --filters "Name=tag-key,Values=c7n-tutorial" --query 'Reservations[*].Instances[*].{Instance:InstanceId,tagKey:Tags[?Key==`c7n-tutorial`]|[0].Key,tagValue:Tags[?Key==`c7n-tutorial`]|[0].Value,State:State.Name}' --output table
```

These commands will be referenced below and have been provided for you to easily copy and paste!

## Executing Your First Cloud Custodian Policy

**1. Describe Instances**

First check on your EC2 instances in CloudShell by running the AWS CLI for `describe-instances` referenced above. The result should be an output of a table listing two instances: both of them should be tagged “c7n-tutorial,” but only one of them should have a tag key value of “my-first-policy-pull.” Both of them should be in a running state.

**2. Make Sure Your Policy File Is Correct**

Using the `custodian validate` command, check your policy file for correctness.

**3. Execution Without Consequences**

If your policy file is correct, try a dry run by copying and pasting and running the `custodian run` command exactly as it appears above. Make sure you include the `--dryrun` flag! You should see some Cloud Custodian logs and notice a new directory named after your policy containing logs, metadata, and resources files.

**4. Report Your Findings**

Use the `custodian report` command to see the output of your policy filters. The result should be an output of a table with just one entry: the EC2 instance with the value “my-first-policy-pull” for the tag key “c7n-tutorial.” This is the instance your policy will perform its actions on once you remove the `--dryrun` flag.

**5. Lower Your Flag**

Speaking of removing flags, are you ready to execute your policy for real? If you have not already done so, go ahead and execute your policy without `--dryrun`.

**6. Did It Work?**

Now, when you run the AWS CLI to describe instances, you should notice that one of your EC2 instances has a different tag value. Instead of “my-first-policy-pull,” the new value should be “it worked!” You will also notice its state has been changed to either `stopped` or `stopping`. Not surprisingly, if you compare the ID of this instance with the ID of the instance generated by `custodian report`, you will find they are the same.    

Congratulations! You have successfully written and executed your first Cloud Custodian policy! While this is a very simple example policy, it is not difficult to imagine more sophisticated implementations of Cloud Custodian at scale.

# Extra Credit

## Cleaning Up After Yourself

If you don’t want to leave a bunch of test EC2s littering your AWS estate, you can use Cloud Custodian to terminate the instances associated with this tutorial. You can use a Cloud Custodian policy similar to the one you already executed with just a couple changes. Like the `my-first-policy-pull-stop-tagged-ec2` policy, you will want to filter for specific EC2s and take an action on them.

## A Handful of Hints

* In Cloud Custodian, you can check if a tag is merely present. So instead of `tag:c7n-tutorial: "my-first-policy-pull"` you can use `tag:c7n-tutorial: present`.
* You can explore which filters and actions are available for a resource by running `custodian schema <resource>.actions`. So, for example, in order to see all actions available for an EC2 instance, you would run `custodian schema ec2.actions`.
* Remember to use `custodian validate` to make sure your policy file is written correctly and the `--dryrun` flag and `custodian report` command to verify your policy will do what you think it does before committing to any irreversible actions.
* You can find the answer [here](c7n-tutorial-cleanup.yml).

# Further Reading and Resources

* Check out [CloudCustodian.io](https://cloudcustodian.io/) to find links to documentation, the project repo, and more
* The [Cloud Custodian Gitter](https://gitter.im/cloud-custodian/cloud-custodian) is a good place to ask questions and get answers from other c7n users
* In the [Community repo](https://github.com/cloud-custodian/community), you can find a calendar of Cloud Custodian events and other resources
* Tune into one of our [webinars](https://app.livestorm.co/stacklet-io) to learn more
# Configure the AWS Provider
provider "aws" {
}

# Creates lambda role for event-based policies
resource "aws_iam_role" "c7n-workshop-lambda-iam-role" {
  name               = "c7n-workshop-lambda-role"
  path               = "/system/"
  assume_role_policy = file("c7n-workshop-trust-policy.json")

  inline_policy {
    name   = "c7n-workshop-policy"
    policy = file("c7n-workshop-policy.json")
  }

  tags = {
    "c7n-workshop" : " "
  }
}

# Creates unencrypted sqs queue
resource "aws_sqs_queue" "c7n-workshop-queue" {
  name = "c7n-workshop-queue"

  tags = {
    "c7n-workshop" : " "
    "Name" : "c7n-workshop-queue"
  }
}

# Creates open security group
resource "aws_security_group" "c7n-workshop-security-group" {

  name = "c7n-workshop-security-group"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "c7n-workshop" : " "
    "Name" : "c7n-workshop-security-group"
  }
}

# Configure the AWS Provider
provider "aws" {
}

# AMI to use for EC2 instances
data "aws_ami" "amazon-linux-2" {
  most_recent = true
  owners = ["amazon"]
  
  filter {
    name   = "owner-alias"
    values = ["amazon"]
 }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Creates 3 EC2s with different tagging
resource "aws_instance" "my-first-policy-pull-stop-not-tagged-ec2" {
  ami           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "t2.micro"
  count         = 1
  tags = {
    "c7n-101" : " "
  }
}

resource "aws_instance" "my-first-policy-pull-stop-tagged-ec2" {

  ami           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "t2.micro"
  count         = 1
  tags = {
    "c7n-101" : "my-first-policy-pull"
  }
}

resource "aws_instance" "my-first-policy-event-stop-tagged-ec2" {
  ami           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "t2.micro"
  count         = 1
  tags = {
    "c7n-101" : "my-first-policy-event"
  }
}

# Creates lambda role for event-based policies
resource "aws_iam_role" "c7n-101-lambda-iam-role" {
  name               = "c7n-101-lambda-role"
  path               = "/system/"
  assume_role_policy = file("my-first-policy-event-trust-policy.json")

  inline_policy {
    name   = "my-first-policy-event-rw-ec2-cloudwatch-policy"
    policy = file("my-first-policy-event-rw-ec2-cloudwatch-policy.json")
  }

  tags = {
    "c7n-101" : " "
  }
}

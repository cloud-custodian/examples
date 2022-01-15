# Creates EC2s: 2 with "c7n-101" key-value tag, 1 with no key-value tag
resource "aws_instance" "my-first-policy-pull-stop-not-tagged-ec2" {
  ami           = "ami-00eb20669e0990cb4"
  instance_type = "t2.micro"

  count = 1

  tags = {
    "c7n-101" : " "
  }
}

resource "aws_instance" "my-first-policy-pull-stop-tagged-ec2" {
  ami           = "ami-00eb20669e0990cb4"
  instance_type = "t2.micro"

  count = 1

  tags = {
    "c7n-101" : "my-first-policy-pull"
  }
}

resource "aws_instance" "my-first-policy-event-stop-tagged-ec2" {
  ami           = "ami-00eb20669e0990cb4"
  instance_type = "t2.micro"

  count = 1

  tags = {
    "c7n-101" : "my-first-policy-event"
  }
}


# Creates lambda role for event-based policies
resource "aws_iam_role" "my-first-policy-event-stop-tagged-ec2" {
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

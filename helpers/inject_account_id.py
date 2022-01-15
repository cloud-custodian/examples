import boto3
import yaml

account_id = boto3.client("sts").get_caller_identity()["Account"]

with open("resources/example-policies/my-first-policy-event.yml", 'r') as stream:
    try:
        loaded = yaml.safe_load(stream)
    except yaml.YAMLError as exc:
        print(exc)

# Modify the fields from the dict
loaded['policies'][0]['mode']['role'] = loaded['policies'][0]['mode']['role'].replace('{your_account_id}', account_id)

# Save it again
with open("resources/example-policies/my-first-policy-event.yml", 'w') as stream:
    try:
        yaml.safe_dump(loaded, stream, default_flow_style=False)
    except yaml.YAMLError as exc:
        print(exc)
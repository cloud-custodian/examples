import boto3
from colorama import Fore, Back, Style
import os
import yaml

def inject_account_id():
    # Updates policy files:
    # If the policy file contains `{your_account_id}`, replaces `{your_account_id}` with accound ID extracted from STS so policy can be executed
    # If the policy file contains account ID, replaces account ID with `{your_account_id}` so you don't accidentally commit account ID to Git 
    
    account_id = boto3.client('sts').get_caller_identity()['Account']
    path = '/Users/lacosta/Desktop/ESCAPE-HATCH/development/examples/resources/example-policies'

    policy_files = [file for file in os.listdir(path) if os.path.isfile(os.path.join(path,file))]

    for policy_file in policy_files:

        # Load YAML file as JSON
        with open(os.path.join(path,policy_file), 'r') as stream:
            try:
                loaded = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc)

        # Check if the policy has a `mode` and therefore a `role` that might need to be updated
        # And if so, replace with account ID extracted from STS
        for policy in loaded['policies']:
            if 'mode' in policy:
            # Check if the policy has a `mode` and therefore a `role` that might need to be updated

                if '{your_account_id}' in policy['mode']['role']:
                # If `role` contains `{your_account_id}`, replace with accound ID    
                    
                    print(Fore.RED + Back.GREEN + "`{your_account_id}` found in file: %s, replacing with account ID" %(policy_file))
                    policy['mode']['role'] = policy['mode']['role'].replace('{your_account_id}', account_id)
                
                elif account_id in policy['mode']['role']:
                # If `role` contains account ID, replace with `{your_account_id}`
                    
                    print(Fore.RED + Back.GREEN + "Account ID found in file: %s, replacing with `{your_account_id}`" %(policy_file))
                    policy['mode']['role'] = policy['mode']['role'].replace(account_id, '{your_account_id}')

        # Save the file
        with open(os.path.join(path,policy_file), 'w') as stream:
            try:
                yaml.safe_dump(loaded, stream, sort_keys=False)
            except yaml.YAMLError as exc:
                print(exc)

if __name__ == "__main__":
    inject_account_id()
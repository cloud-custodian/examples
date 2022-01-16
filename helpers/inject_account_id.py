import pathlib
import boto3
from colorama import Fore
import os
import yaml

def inject_account_id():
    # Updates policy files:
    # If the policy file contains `{your_account_id}`, replaces `{your_account_id}` with accound ID extracted from STS so policy can be executed
    # If the policy file contains account ID, replaces account ID with `{your_account_id}` so you don't accidentally commit account ID to Git 
    
    account_id = boto3.client('sts').get_caller_identity()['Account']
    path = os.getcwd() + '/resources/example-policies'
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

                    user_input = input(Fore.RED + "`{your_account_id}` found in file: %s. Would you like to replace it with account ID? yes/no " %(policy_file))

                    if user_input == "yes":
                        
                        print(Fore.RED + "User input: %s. Replacing `{your_account_id}` in file: %s with account ID." %(user_input, policy_file))
                        policy['mode']['role'] = policy['mode']['role'].replace('{your_account_id}', account_id)
                    
                        # Save the file
                        with open(os.path.join(path,policy_file), 'w') as stream:
                            try:
                                yaml.safe_dump(loaded, stream, sort_keys=False)
                            except yaml.YAMLError as exc:
                                print(exc)
                    
                    else:   
                    
                        print(Fore.RED + "User input: %s. Skipping file: %s." %(user_input, policy_file))
                
                elif account_id in policy['mode']['role']:
                # If `role` contains account_id, replace with `{your_account_id}`

                    user_input = input(Fore.RED + "Account ID found in file: %s. Would you like to replace it with `{your_account_id}`? yes/no " %(policy_file))

                    if user_input == "yes":
                        
                        print(Fore.RED + "User input: %s. Replacing account ID in file: %s with `{your_account_id}`." %(user_input, policy_file))
                        policy['mode']['role'] = policy['mode']['role'].replace(account_id, '{your_account_id}')

                        # Save the file
                        with open(os.path.join(path,policy_file), 'w') as stream:
                            try:
                                yaml.safe_dump(loaded, stream, sort_keys=False)
                            except yaml.YAMLError as exc:
                                print(exc)

                    else:   
                    
                        print(Fore.RED + "User input: %s. Skipping file: %s." %(user_input, policy_file))



if __name__ == "__main__":
    inject_account_id()
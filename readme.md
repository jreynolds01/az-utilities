# az-utilities

This repository is just for utilities that support connecting to azure.

## Dependencies

Right now, the scripts are run in Ubuntu on Windows, leveraging the Windows Subsystem for Linux (WSL).

To set up the environment, I've just installed azure-cli, based on instructions [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest).

## Contents

- `update_vnet.sh`: updates vnet security rules to allow ssh connections from outside of CORPNET
  - Usage: `update_vnet.sh <resource_group_name>`
  - Args:
    - `<resource_group_name>`: the resource group name of the VM. Currently assumes the name of the VM's vnet is <resource_group_name>-vnet. See script for work arounds for a custom vnet (not automated yet).
  - Example:
    - `update_vnet.sh jeremr_recotst0`

Note - that security rule is updated periodically, so you basically need to ssh immediately after:

```shell
update_vnet.sh jeremr_recotst0
ssh -i my_rsa_file myid@mydsvm.eastus2.cloudapp.azure.com
```

# az-utilities

This repository is just for utilities that support connecting to azure.

## Dependencies

Right now, any bash scripts are run in Ubuntu on Windows, leveraging the Windows Subsystem for Linux (WSL). Powershell is just default powershell.

### Bash env setup

To set up the bash environment, I've just installed azure-cli, based on instructions [here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest).

You must also set the `AZ_SUB` environment variable to store the azure subscription ID.

### Powershell env setup

To set up the powershell environment, you need to install a couple of modules.

- AzureRM (`Install-Module -Name AzureRM`)
- AzureRM.Security (`Install-Module -Name AzureRM.Security -AllowPrerelease`)

You can install both without elevated permissions using the argument `-Scope CurrentUser`. Note that these leverage the older `AzureRM` module and not `Az`, because the Security module does not support `Az` yet.

## Contents

- `update_vnet.sh`: updates vnet security rules to allow ssh connections from outside of our internal network.
  - Usage: `update_vnet.sh <resource_group_name> <SSH_ARGS>`
  - Parameters:
    - `<resource_group_name>`: the resource group name of the VM. Currently assumes the name of the VM's vnet is `<resource_group_name>-vnet`. See script for work arounds for a custom vnet (not automated yet).
    - `<SSH_ARGS>`: additional arguments passed to ssh to do the connection.
  - Example:
    - `update_vnet.sh jeremr_recotst0` ## Just update rule, don't try to ssh 
    - `update_vnet.sh jeremr_recotst0 -i ~/.ssh/my_id_file myid@myvm.region.cloudapp.azure.com` ## Update the rule and ssh with a custom id file, user, and URL
    - `update_vnet.sh jeremr_recotst0 reco` ## Update the rule and leverage ssh_config file to connect to the profile associated with `reco`
    - `update_vnet.sh jeremr_recotst0 -R 8000:localhost:8000 reco` ## Update the rule and leverage ssh_config file to connect to the profile associated with `reco`

Note - that security rule is updated periodically, so you basically need to ssh immediately after:

```shell
update_vnet.sh jeremr_recotst0
ssh -i my_rsa_file myid@mydsvm.eastus2.cloudapp.azure.com
```

Also note that it takes a few moments for the updates to propagate, so occasionally ssh from the tool will fail, and you'll still have to manually ssh in.

## ssh_config setup

You can place a file named `config` within the .ssh directory so that it can govern your connections. A simple setup for this is:

```ssh_config
## DSVM for recommendations testing
Host myprofilename
    HostName myhostname.eastus2.cloudapp.azure.com
    Port 22
    User MyVMId
    IdentityFile ~/.ssh/id_rsa_mine
```

## Using a Just-In-Time (JIT) Policy

See details of the feature [here](https://docs.microsoft.com/en-us/azure/security-center/security-center-just-in-time)

This requires that this feature has been enabled for the VM. To do so, in the blade of the VM, select the "Configuration" option in Settings, and select the button "Enable Just-In-Time policy." Once that's enabled, you
can use the script `request-jitaccess.ps1` to request access.

See above for requirements.

At some point, you will need to run `Connect-AzureRmAccount` to make sure you are signed into Azure.

After running the powershell script, you should wait 20-30 seconds before trying to ssh into your VM - updating the rules is done asynchronously, and it takes some time to propagate.
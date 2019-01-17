#!/usr/bin/env bash

# Usage: update_vnet.sh <RG_NAME> <SSH_ARG0> <SSH_ARG1> ...
# update_vnet.sh jeremy_rg
# update_vnet.sh jeremy_rg -i my_id_file myacct@myvm.ip.addrs.com


# just start with numbered args
RG_NAME=$1
VNET_NAME=${RG_NAME}-vnet
VERBOSE=1
## Rule name is probably this:
SECURITY_RULE_NAME="Cleanuptool-Allow-100"


# make sure an argument is passed
if [ $# -eq 0 ]; then
    echo "*** No arguments supplied"
    echo ""
    echo "   Usage: "$0" <RESOURCE_GROUP_NAME> <SSH_ARG0> <SSH_ARG1> ..."
    echo "   e.g. "
    echo "   "$0" myvmrg"
    echo "   "$0" myvmrg -i my_id_file myacct@myvm.mydnsname.com"
    echo ""
    exit
fi

# Get additional args
if [ $# -gt 1 ]; then
    args=("$@")
    SSH_ARGS=${args[*]/$1}
    SSH_CMD="ssh $SSH_ARGS"
    echo "*** More than 1 argument passed. Using additional args for ssh. Constructed command: $SSH_CMD"
fi

# Get my IP Address:
echo "Getting current IP address."
MY_IP_ADDR=$(curl ifconfig.me)
echo "*** Adding $MY_IP_ADDR"

# LOGIN IF NECESSARY
list=`az account list -o table`
if [ "$list" == '[]' ]; then
  echo "*** LOGGING INTO AZURE..."
  LOGIN_OUTPUT=$(az login -o table)
else
  echo "*** Already logged in to Azure."
fi

# echo $LOGIN_OUTPUT

# Make sure AZ_SUB env is set
# if not, bail
if [ -z ${AZ_SUB+x} ]; then 
    echo "Azure subscription is NOT set in the AZ_SUB env variable. Please set it before continuing."; 
    exit
else 
    echo "*** Using Azure subscription from AZ_SUB env variable"; 
fi

# should probably just use -s option, rather than setting it as default here...
# this has potential to 
echo "*** Setting default subscription to that stored in AZ_SUB env variable."
az account set -s ${AZ_SUB}

# if not default vnet name, then can get from VM information:
# list network interfaces, to get the name of the relevant one (likely to just be the one)
# az vm nic list -g ${RG_NAME} --vm-name ${VM_NAME}
# Get the id, the tail of which is the --nic for the show command
# az vm nic show -g ${RG_NAME} --vm-name ${VM_NAME} --nic ${NIC_NAME} --query ipConfigurations[0].subnet.id
## Once you get vnet name:
echo "*** Getting the necessary Network Security Group..."
cmd="az network vnet subnet list -g ${RG_NAME} --vnet-name ${VNET_NAME} --query [].networkSecurityGroup.id"
# Extra parentheses needed to convert output to bash array:
NSG_INFO=($($cmd | awk -F"/" '$0~"subscriptions"{OFS="\t"; gsub("\"","", $NF); print $5, $NF}'))
NSG_RG_NAME=${NSG_INFO[0]}
NSG_NAME=${NSG_INFO[1]}

## The following pieces aren't necessary if SECURITY_RULE_NAME is accurate:
## If you need to get the SECURITY_RULE_NAME this is a start:
## az network nsg show -g ${NSG_RG_NAME} -n ${NSG_NAME}
# Can look at the rule these ways:
# az network nsg rule list -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --query [?name=='Cleanuptool-Allow-100']
#OR:
## This query needs some quotes around it in bash, but not in pwsh...
# az network nsg rule show -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --name ${SECURITY_RULE_NAME} \
#   --query '{ObjID:id,sourceAddressPrefix:sourceAddressPrefixes}'

## Get the current IPs that should have access
echo "*** Getting Current Prefixes..."
SHOW_CMD="az network nsg rule show -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --name ${SECURITY_RULE_NAME} --query sourceAddressPrefixes"
CURRENT_PREFIXES=$($SHOW_CMD | awk '$0~"[0-9]{1,}.[0-9]{1,}"{ORS=" "; gsub("\"","""");gsub(",","");print $0} END{print "\n"}')

## Update address prefixes with the current IP and the old ones. 
echo "*** Updating security rule..."
cmd="az network nsg rule update -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --name ${SECURITY_RULE_NAME} --source-address-prefixes $MY_IP_ADDR $CURRENT_PREFIXES"
# echo $cmd
## Prints out the result by default, so no need to do so manually
UPDATE_OUTPUT=$($cmd)

# use additional args for ssh
if [ $# -gt 1 ]; then
    echo "*** Connecting..."
    $SSH_CMD
fi
exit


# --source-address-prefixes      : Space-separated list of CIDR prefixes or IP ranges.
#                                     Alternatively, specify ONE of 'VirtualNetwork',
#                                     'AzureLoadBalancer', 'Internet' or '*' to match all IPs.

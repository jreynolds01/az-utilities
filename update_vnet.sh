#!/usr/bin/env bash

# Usage: update_vnet.sh <RG_NAME>
# update_vnet.sh jeremr_recotest0

# just start with numbered args
RG_NAME=$1
VNET_NAME=${RG_NAME}-vnet
VERBOSE=1
SECURITY_RULE_NAME="Cleanuptool-Allow-100"

# Get my IP Address:
MY_IP_ADDR=$(curl ifconfig.me)
echo "*** Adding $MY_IP_ADDR"

# make sure an argument is passed
if [ $# -eq 0 ]
  then
    echo "** No arguments supplied"
    echo ""
    echo "   Usage: "$0" <RESOURCE_GROUP_NAME>"
    echo "   e.g. "
    echo "   "$0" myvmrg"
    echo ""
fi


# LOGIN IF NECESSARY
list=`az account list -o table`
if [ "$list" == '[]' ]; then
  echo "*** LOGGING INTO AZURE..."
  LOGIN_OUTPUT=$(az login -o table)
else
  echo "*** Already logged in."
fi

# echo $LOGIN_OUTPUT

# Make sure AZ_SUB env is set
# if not, bail
if [ -z ${AZ_SUB+x} ]; then 
    echo "Azure subscription is NOT set in AZ_SUB"; 
    exit
else 
    echo "*** Using Azure subscription from AZ_SUB env variable"; 
fi

# just use -s option, rather than setting it later
# az account set -s ${AZ_SUB}

# if not default vnet name, then can get from VM information:
# list network interfaces, to get the name of the relevant one (likely to just be the one)
# az vm nic list -g ${RG_NAME} --vm-name ${VM_NAME}
# Get the id, the tail of which is the --nic for the show command
# az vm nic show -g ${RG_NAME} --vm-name ${VM_NAME} --nic ${NIC_NAME} --query ipConfigurations[0].subnet.id
## Once you get vnet name:
## need quotes to run on 
cmd="az network vnet subnet list -g ${RG_NAME} --vnet-name ${VNET_NAME} --query [].networkSecurityGroup.id"
# echo $cmd
# Extra parentheses needed to convert output to bash array:
NSG_INFO=($($cmd | awk -F"/" '$0~"subscriptions"{OFS="\t"; gsub("\"","", $NF); print $5, $NF}'))
NSG_RG_NAME=${NSG_INFO[0]}
NSG_NAME=${NSG_INFO[1]}

## Not needed if you already know the name:
## If you need to get the name this is a start:
## az network nsg show -g ${NSG_RG_NAME} -n ${NSG_NAME}

# RuleName is likely: CleanupToolAllow-100
# Can look at it this way:
# az network nsg rule list -g cleanupservice --nsg-name rg-cleanupservice-nsg18 --query [?name=='Cleanuptool-Allow-100']
#OR:
## This quary needs some quotes around it in bash...
## not necessary
# az network nsg rule show -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --name ${SECURITY_RULE_NAME} \
#   --query '{ObjID:id,sourceAddressPrefix:sourceAddressPrefixes}'

SHOW_CMD="az network nsg rule show -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --name ${SECURITY_RULE_NAME} --query sourceAddressPrefixes"
CURRENT_IPS=$($SHOW_CMD | awk '$0~"[0-9]{1,}.[0-9]{1,}"{ORS=" "; gsub("\"","""");gsub(",","");print $0} END{print "\n"}')

## Will be something like this: 
echo "Updating security rule..."
cmd="az network nsg rule update -g ${NSG_RG_NAME} --nsg-name ${NSG_NAME} --name ${SECURITY_RULE_NAME} --source-address-prefixes $MY_IP_ADDR $CURRENT_IPS"
## Prints out the result by default...
$cmd

## print out new IP list
# $SHOW_CMD | awk '$0~"[0-9]{1,}.[0-9]{1,}"{ORS="\n"; gsub("\"","""");gsub(",","");print $0}'
exit


# --source-address-prefixes      : Space-separated list of CIDR prefixes or IP ranges.
#                                     Alternatively, specify ONE of 'VirtualNetwork',
#                                     'AzureLoadBalancer', 'Internet' or '*' to match all IPs.

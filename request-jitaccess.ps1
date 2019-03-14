<#
.SYNOPSIS
  Submits a JIT access request to enable access to a specified virtual machine.
.DESCRIPTION
  See Synopsis.
.PARAMETER setenvfile
  Powershell script to run to set appropriate environment variables
.PARAMETER subscription
  Subscription id that contains the virtual machine
.PARAMETER resource_group
  Resource group that houses the virtual machine
.PARAMETER vmname
  Name of the virutal machine
.PARAMETER location
  Region of the virtual machine (e.g. eastus). Needed for Security Center.
.PARAMETER verbose
  Verbose produces more output (default = 0)
.EXAMPLE
  .\request-jitaccess.ps1 -subscription 00000000-0000-0000-0000-00000 -resource_group my_rg -vmname myvmname -location eastus
.NOTES
  Author: Jeremy Reynolds
  Date: January 17, 2019
#>
param(
  [string]$setenvfile,
  [string]$subscription,
  [string]$resource_group,
  [string]$vmname,
  [string]$location,
  [bool]$verbose = $false
)

## parse and run this first!
IF(!([string]::IsNullOrEmpty($setenvfile))) {            
  ## dot source the setenvfile
  Write-Host "Setting variables according to $setenvfile"
  . $setenvfile
}

# Fill in default values...
IF([string]::IsNullOrEmpty($subscription)) {            
  ## Try to get it from env variable
  IF (Test-Path Env:vm_subscription) {
    $subscription = Get-Item Env:vm_subscription | Select -expand "value"
    IF ($verbose){
      Write-Host "*** Set subscription to value stored in Env:vm_subscription:" $subscription
    }
  }
  else {            
    Write-Host ""
    Write-Host "*** Error: No subscription parameter passed, and no environment variable set. Aborting."
    Write-Host ""
    exit
  }
} 

IF([string]::IsNullOrEmpty($resource_group)) {            
  ## Try to get it from env variable
  IF (Test-Path Env:vm_resource_group) {
    $resource_group = Get-Item Env:vm_resource_group | Select -expand "value"
    IF ($verbose){
      Write-Host "*** Set resource_group to value stored in Env:vm_resource_group:" $resource_group
    }
  }
  else {            
    Write-Host ""
    Write-Host "*** Error: No resource_group parameter passed, and no environment variable set. Aborting."
    Write-Host ""
    exit
  }
} 

IF([string]::IsNullOrEmpty($vmname)) {            
  ## Try to get it from env variable
  IF (Test-Path Env:vm_name) {
    $vmname = Get-Item Env:vm_name | Select -expand "value"
    IF ($verbose){
      Write-Host "*** Set vmname to value stored in Env:vm_name:" $vmname
    }
  }
  else {            
    Write-Host ""
    Write-Host "*** Error: No vmname parameter passed, and no environment variable set. Aborting."
    Write-Host ""
    exit
  }
} 

IF([string]::IsNullOrEmpty($location)) {            
  ## Try to get it from env variable
  IF (Test-Path Env:vm_location) {
    $location = Get-Item Env:vm_location | Select -expand "value"
    IF ($verbose){
      Write-Host "*** Set location to value stored in Env:vm_location:" $location
    }
  }
  else {            
    Write-Host ""
    Write-Host "*** Error: No location parameter passed, and no environment variable set. Aborting."
    Write-Host ""
    exit
  }
} 


# Dependencies: Az.Security
# 
# wrap to check this:
# Connect-AzAccount -SubscriptionId $subscription

$ip = Invoke-RestMethod http://ipinfo.io/json | Select-Object -exp ip
$endTimeUtc = (Get-Date).AddHours(1).toUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

# construct the ID strings and objects:
$vm_id = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Compute/virtualMachines/{2}" -f $subscription, $resource_group, $vmname

$jit_id = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Security/locations/{2}/jitNetworkAccessPolicies/default" -f $subscription, $resource_group, $location

$JitPolicyVm1 = (@{
  id=$vm_id
  ports=(@{
   number=22;
   endTimeUtc=$endTimeUtc;
   allowedSourceAddressPrefix=@($ip)})
   })

$JitPolicyArr=@($JitPolicyVm1)

# Submit the request!
Start-AzJitNetworkAccessPolicy -ResourceId $jit_id -VirtualMachine $JitPolicyArr

## probably want to wait 20 s after executing it before using ssh

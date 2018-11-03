#requires -version 4.0
# -----------------------------------------------------------------------------
# Script: 
# Author: Eric RABOTTEAU 
# Date: 
# Keywords:
# Comments:
#
# -----------------------------------------------------------------------------

Function Invoke-ESXHostRestart()
{
    param(
            [Parameter(Mandatory=$True)][string]$VCenter,
            [Parameter(Mandatory=$True)][string]$ESXHostName,
            [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential
        )

    #region definition variables globales du script
    Import-Module Usefull-Tools
    Get-Module -Name VMware* -ListAvailable | Import-Module
    Connect-VIServer $vcenter -Credential $Credential |Out-Null

    # Get host OBJECT
    $ESXHostObject = Get-VMHost -Name $ESXHostName
    $csvfile="c:\var\$($ESXHostName).txt"



    #list vms avant maintenance
    show-MyLogger "export List of Vm running on host $ESXHostName" -Color Cyan
    Get-VM | ? { $_.VMHost -like $ESXHostName }|Select Name | Export-Csv $csvfile -NoTypeInformation -UseCulture

    #put server in maintenance mode
    show-MyLogger "Entering Maintenance Mode" -Color Cyan
    Set-VMHost -VMHost $ESXHostObject -State Maintenance -Confirm:$false -Evacuate | out-null



    # reboot host
    show-MyLogger "Shutting down $ESXHostName" -Color Cyan
    Restart-VMHost $ESXHostName -Confirm:$false | out-null



    # Wait for Server to show as down
    do {
    sleep 15
    $ServerState = (get-vmhost $ESXHostName).ConnectionState
    }
    while ($ServerState -ne "NotResponding")
    show-MyLogger "$ESXHostName is Down" -Color red
 

    # Wait for server to reboot
    do {
    sleep 60
    $ServerState = (get-vmhost $ESXHostName).ConnectionState
    show-MyLogger "Waiting for Reboot ..." -Color Yellow
    }
    while ($ServerState -ne "Maintenance")
    show-MyLogger "$ESXHostName is back up" -Color Green




    # Exit Maintenance Mode
    show-MyLogger "Exiting Maintenance Mode" -Color Yellow
    set-vmhost -VMHost $ESXHostObject -State Connected |Out-Null

    show-mylogger "Waiting for 30 seconds" -Color Green
    Start-Sleep -Seconds 30


    $vms=Import-Csv $csvfile
    show-MyLogger "Move back VMs on $ESXHostName" -Color Cyan
    foreach ($vm in $vms.name) {
        show-MyLogger "Relocate Virtual Machine $vm back on $ESXHostName" -Color Green
        $a=(Get-VM -name $vm | move-vm -Destination $ESXHostObject -RunAsync)
    }
    ##########################################################################
    # cleaup
    ##########################################################################
    Disconnect-VIServer -Server $VCenter -Confirm:$false
    Remove-Item $csvfile -Force -Confirm:$False
}
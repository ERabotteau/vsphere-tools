#requires -version 4.0
# -----------------------------------------------------------------------------
# Script: 
# Author: Eric RABOTTEAU 
# Date: 
# Keywords:
# Comments:
# 
#
# -----------------------------------------------------------------------------

Function Invoke-ESXHostUpdate() 
{
    param(
        [Parameter(Mandatory=$True)][string]$VCenter,
        [Parameter(Mandatory=$True)][string]$ESXHostName,
        [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential
    )



    #region definition variables globales du script
    Import-Module Usefull-Tools
    $BaseLineName = "ESXi_{0}_Latest"
    Connect-VIServer $vcenter -Credential $Credential
    # Get host OBJECT
    $ESXHostObject = Get-VMHost -Name $ESXHostName
    $csvfile="c:\var\$($ESXHostName).txt"
    #get baseline OBJECT
    #rename baseline using esx host version
    $baselineName=$baselinename -f $ESXHostObject.version
    $BaselineObject = Get-Baseline -Name $baselineName


    #list vms avant maintenance
    show-MyLogger "export List of Vm running on host $ESXHostName"
    Get-VM | ? { $_.VMHost -like $ESXHostName }|Select Name | Export-Csv $csvfile -NoTypeInformation -UseCulture
    #attach baseline to host
    show-MyLogger "Scan host $ESXHostName for $baselineName Baseline"
    Attach-Baseline -Entity $ESXHostObject -Baseline $BaselineObject
    #scan host
    Scan-Inventory -Entity $ESXHostObject


    show-MyLogger "Entering Host $ESXHostName in Maintenance Mode" -Color Green
    Set-VMHost -VMHost $ESXHostObject -State Maintenance -Confirm:$false -ErrorAction SilentlyContinue |Out-Null
    show-MyLogger "Waiting 10 seconds"
    Start-Sleep -Seconds 10


    show-MyLogger "Apply $BaseLineName Baseline" -Color Yellow
    remediate-inventory -baseline $BaselineObject -Entity $ESXHostObject -confirm:$false |Out-Null

    show-MyLogger "Server is back waiting for 30s before exiting maintenance Mode !" -Color cyan
    Start-Sleep -Seconds 30


    show-MyLogger "$ESXHostName exits Maintenance Mode" -Color Yellow
    set-vmhost -VMHost $ESXHostObject -State Connected |Out-Null

    do {
        Start-Countdown -Seconds 30 -Message "Waiting..."
        $ServerState = (get-vmhost $ESXHostName).ConnectionState
        show-MyLogger "Waiting for Connection State ..." -Color Yellow
        }
        while ($ServerState -ne "Connected")

    show-MyLogger "Server is connected waiting for 30s more !" -Color cyan
    Start-Sleep -Seconds 30



 
    $vms=Import-Csv $csvfile
    show-MyLogger "Move back VMs on $ESXHostName" -Color Cyan
    foreach ($vm in $vms.name) {
        show-MyLogger "START : move $vm back to $ESXHostName" -Color Green
        $a=(Get-VM -name $vm | move-vm -Destination $ESXHostName)
        #$a=(Get-VM -name $vm | move-vm -Destination $vmhost -RunAsync)
        show-MyLogger "END : move $vm back to $ESXHostName" -Color Green
    }



show-MyLogger "Disconnecting from $vcenter"
Disconnect-VIServer -Server $vcenter -ErrorAction SilentlyContinue -confirm:$false |Out-Null
}
###############################################################################
# End script
###############################################################################
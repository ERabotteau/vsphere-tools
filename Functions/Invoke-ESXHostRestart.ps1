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
    [CmdletBinding()]
    param(
            [Parameter(Mandatory=$True)][string]$VCenter,
            [Parameter(Mandatory=$True)][string]$ESXHostName,
            [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential
        )

    begin {
        try {
            Connect-VIServer $vcenter -Credential $Credential  -ErrorAction Stop |Out-Null
            show-MyLogger "Success : Connected to vcenter" -Color Green
        } catch {
            show-MyLogger "Error : not connected to vcenter $VCenter" -Color red
            break
        }
        $csvdir="c:\var"
        If(!(test-path $csvdir)) {
              New-Item -ItemType Directory -Force -Path $csvdir
        }
    }

    process {
        # Get host OBJECT
        $ESXHostObject = Get-VMHost -Name $ESXHostName
        $csvfile="$(csvdir)\$($ESXHostName).txt"

        #list vms avant maintenance
        show-MyLogger "export List of Vm running on host $ESXHostName"
        Get-VM | ? { $_.VMHost -like $ESXHostName }|Select Name | Export-Csv $csvfile -NoTypeInformation -UseCulture

        #put server in maintenance mode
        show-MyLogger "Entering Maintenance Mode"
        Set-VMHost -VMHost $ESXHostObject -State Maintenance -Confirm:$false -Evacuate | out-null

        # reboot host
        show-MyLogger "Shutting down $ESXHostName"
        Restart-VMHost $ESXHostName -Confirm:$false | out-null

        # Wait for Server to show as down
        do {
        sleep 15
        $ServerState = (get-vmhost $ESXHostName).ConnectionState
        }
        while ($ServerState -ne "NotResponding")
        show-MyLogger "$ESXHostName is now Down"
 

        # Wait for server to reboot
        do {
        sleep 60
        $ServerState = (get-vmhost $ESXHostName).ConnectionState
        show-MyLogger "Waiting for Reboot ..." -Color Cyan
        }
        while ($ServerState -ne "Maintenance")
        show-MyLogger "$ESXHostName is back online"




        # Exit Maintenance Mode
        show-MyLogger "Exiting Maintenance Mode"
        set-vmhost -VMHost $ESXHostObject -State Connected |Out-Null


        show-mylogger "Waiting for 30 seconds" -Color Cyan
        Start-Sleep -Seconds 30


        $vms=Import-Csv $csvfile
        show-MyLogger "Move back VMs on $ESXHostName"
        foreach ($vm in $vms.name) {
            show-MyLogger "Relocate Virtual Machine $vm back on $ESXHostName"
            show-MyLogger "START : move $vm back to $ESXHostName" -Color Green
            $a=(Get-VM -name $vm | move-vm -Destination $ESXHostName)
            show-MyLogger "END : move $vm back to $ESXHostName" -Color Green
        }
    }

    end {
        show-MyLogger "Disconnecting from $vcenter" -Color Cyan
        Disconnect-VIServer -Server $vcenter -ErrorAction SilentlyContinue -confirm:$false |Out-Null
        Remove-Item -Path $csvfile -Force -ErrorAction SilentlyContinue
        [System.gc]::collect()
        show-MyLogger "Operation successfull"
    }
}
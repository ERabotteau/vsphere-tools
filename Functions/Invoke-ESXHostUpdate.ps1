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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$VCenter,
        [Parameter(Mandatory=$True)][string]$ESXHostName,
        [ValidateNotNull()][System.Management.Automation.PSCredential][System.Management.Automation.Credential()]$Credential
    )

    begin {
        #Import-Module Usefull-Tools
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
        $BaseLineName = "ESXi_{0}_Latest"
        # Get host OBJECT
        $ESXHostObject = Get-VMHost -Name $ESXHostName
        $csvfile="$($csvdir)/$($ESXHostName).txt"
        #rename baseline using esx host version
        $baselineName=$baselinename -f $ESXHostObject.version
        $BaselineObject = Get-Baseline -Name $baselineName

        #list vms avant maintenance
        show-MyLogger "export List of Vm running on host $ESXHostName"
        Get-VM | ? { $_.VMHost -like $ESXHostName }|Select Name | Export-Csv $csvfile -NoTypeInformation -UseCulture
        
        #attach baseline to host and scan
        show-MyLogger "Scan host $ESXHostName for $baselineName Baseline"
        Attach-Baseline -Entity $ESXHostObject -Baseline $BaselineObject
        Scan-Inventory -Entity $ESXHostObject

        #enter maintenance mode
        show-MyLogger "Entering Host $ESXHostName in Maintenance Mode" -Color Green
        Set-VMHost -VMHost $ESXHostObject -State Maintenance -Confirm:$false -ErrorAction SilentlyContinue |Out-Null
        # add 10 more secs
        show-MyLogger "Waiting 10 seconds"
        Start-Sleep -Seconds 10


        #Apply the baseline to host ( host will reboot)
        show-MyLogger "Apply $BaseLineName Baseline"
        remediate-inventory -baseline $BaselineObject -Entity $ESXHostObject -confirm:$false |Out-Null

        #waiting for host being fully available
        show-MyLogger "Server is back but waiting for 30s before exiting maintenance Mode !" -Color cyan
        Start-Sleep -Seconds 30

        #exit maintenance mode
        show-MyLogger "$ESXHostName now exits Maintenance Mode"
        set-vmhost -VMHost $ESXHostObject -State Connected |Out-Null

        show-MyLogger "Waiting for Connection State ..." -Color Cyan
        do {
            $ServerState = (get-vmhost $ESXHostName).ConnectionState
           } while ($ServerState -ne "Connected")

        #server state OK waiting 30s more
        show-MyLogger "Server is connected but waiting for 30s more !" -Color cyan
        Start-Sleep -Seconds 30



        #move back vms to esx host, one at a time
        $vms=Import-Csv $csvfile
        show-MyLogger "Move back VMs on $ESXHostName"
        foreach ($vm in $vms.name) {
            show-MyLogger "START : move $vm back to $ESXHostName" -Color Green
            $a=(Get-VM -name $vm | move-vm -Destination $ESXHostName)
            show-MyLogger "END : move $vm back to $ESXHostName" -Color Green
        }
    }

    end {
        show-MyLogger "Disconnecting from $vcenter" -Color Cyan
        Disconnect-VIServer -Server $vcenter -ErrorAction SilentlyContinue -confirm:$false |Out-Null
        [System.gc]::collect()
        show-MyLogger "Operation successfull"
    }
}
###############################################################################
# End script
###############################################################################
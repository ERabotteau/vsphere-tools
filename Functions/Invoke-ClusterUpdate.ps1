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

Function Invoke-ClusterUpdate() 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)][string]$VCenter,
        [Parameter(Mandatory=$True)][string]$Cluster,
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

    process{
        #get cluster hosts then call esx host update
        $esxhostsNames=(Get-Cluster -Name vdi |Get-VMHost).name
        foreach ($esxhostname in $esxhostsNames) {
            Invoke-ESXHostUpdate -VCenter $VCenter -ESXHostName $esxhostname -Credential $Credential

        }
    }

    end {
        show-MyLogger "Disconnecting from $vcenter" -Color Cyan
        Disconnect-VIServer -Server $vcenter -ErrorAction SilentlyContinue -confirm:$false |Out-Null
        [System.gc]::collect()
        show-MyLogger "Operation successfull"
    }
}
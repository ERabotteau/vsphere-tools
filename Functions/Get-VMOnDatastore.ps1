function Get-VMOnDatastore
{

    param (
	    [parameter(Mandatory=$true, HelpMessage="Enter Vcenter server")][string]$vCenterName,
	    [parameter(Mandatory=$true, HelpMessage="Enter Cluster Name")][string]$ClusterName,
        [parameter(Mandatory=$false, HelpMessage="Export ")][string]$outputfile

    )

    #Connection to the vCenter
    Try{
      $vcenter = Connect-VIServer $vCenterName -ErrorAction "Stop"
    }
    Catch{
      Write-Debug "Error while connecting to the vCenter: $($_.Exception.Message)"
      break
    }

    $myarray=(Get-cluster -Name $ClusterName | Get-Datastore | Foreach-Object {
        $ds = $_.Name
        $_ | Get-VM | Select-Object Name,@{n='DataStore';e={$ds}}
    })
    
    if ($outputfile ) {
        $myarray | Export-Csv $outputfile -NoTypeInformation -UseCulture
    } else {
        $myarray
    }

}

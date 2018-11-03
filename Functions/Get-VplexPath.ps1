function Get-VplexPath
{

    param (
	    [parameter(Mandatory=$false, HelpMessage="Enter Vcenter server")][string]$vCenterName="",
	    [parameter(Mandatory=$false, HelpMessage="Enter Cluster Name")][string]$ClusterName=""
    )
     #Connection to the vCenter
    Try{
      write-host "connecting to vcenter..."
      $vcenter = Connect-VIServer $vCenterName -ErrorAction "Stop"
    }
    Catch{
      Write-Debug "Error while connecting to the vCenter: $($_.Exception.Message)"
      break
    }
    get-cluster -name $ClusterName | Get-VMHost | ForEach-Object {
        $hs=$_.name
        write-host "Scanning $hs" -ForegroundColor Yellow
        $res=(get-vplexdatastorePreferedpathStats -vmhost $hs)
        write-host "$($res.SanID)`t`t$($res.paths)`t`t$($res.Percentage)" -ForegroundColor Green
        write-host "--------------------------"
        }

}
Function Add-VMToDrsGroup {

  param([parameter(Mandatory=$true)] $Cluster,
        [parameter(Mandatory=$true)] $DrsGroup,
        [parameter(Mandatory=$true, ValueFromPipeline=$true)] $VM)

  begin {
    $Cluster = Get-Cluster -Name $Cluster
  }

  process {
    if ($Cluster) {
      if ($DrsGroup.GetType().Name -eq "string") {
        $DrsGroupName = $DrsGroup
        $DrsGroup = Get-DrsGroup -Cluster $Cluster -Name $DrsGroup
      }
      if (-not $DrsGroup) {
        Write-Error "The DrsGroup $DrsGroupName was not found on cluster $($Cluster.name)."
      }
      else {
        if ($DrsGroup.GetType().Name -ne "ClusterVmGroup") {
          Write-Error "The DrsGroup $DrsGroupName on cluster $($Cluster.Name) doesn't have the required type ClusterVmGroup."
        }
        else {
          $VM = $Cluster | Get-VM -Name $VM
          If ($VM) {
            $spec = New-Object VMware.Vim.ClusterConfigSpecEx
            $spec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1)
            $spec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec
            $spec.groupSpec[0].operation = "edit"
            $spec.groupSpec[0].info = $DrsGroup
            $spec.groupSpec[0].info.vm += $VM.ExtensionData.MoRef

            $Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)
          }
        }
      }
    }
  }
}
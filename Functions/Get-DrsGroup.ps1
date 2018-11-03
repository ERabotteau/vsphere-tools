Function Get-DrsGroup {

  param([parameter(Mandatory=$true, ValueFromPipeline=$true)]$Cluster,
        [string] $Name="*")

  process {
    $Cluster = Get-Cluster -Name $Cluster
    if($Cluster) {
      $Cluster.ExtensionData.ConfigurationEx.Group | `
      Where-Object {$_.Name -like $Name}
    }
  }
}
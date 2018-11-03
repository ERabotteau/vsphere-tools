function Set-ActiveDirectoryMemberAsEsxHostAdmin {
<#
   .Synopsis
        This... 
    .Description
        A longer explanation
     .Parameter FOO 
        The parameter...
   .Example
        PS C:\> FOO
        Example- accomplishes 

#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][ValidateNotNullorEmpty()][String[]]$ESXServers,
        [Parameter(Mandatory=$true)][ValidateNotNullorEmpty()][String]$DomainMember
    )


    begin {
    }
    process {
        foreach ( $esxi in $ESXServers) {
            try {
                $ErrorActionPreference='Stop'
                $esxcreds=(Get-Credential -Message "Enter $($esxi) credentials" -UserName root)
                if ( $esxcreds -eq $null) {
                    Show-MyLogger "Abort..."
                    break
                }
                Show-MyLogger "Connecting to $esxi"
                Connect-VIServer $esxi -Credential $esxcreds -WarningAction SilentlyContinue |Out-Null
                Show-MyLogger "Add $DomainMember as admin on $esxi"
                New-VIPermission -role Admin -Principal $DomainMember -Entity $esxi -Propagate:$true
                disconnect-viserver $esxi -confirm:$false
            } catch { 
                Write-Warning $_.Exception.message
            }
        }
    }
    end {
        Show-MyLogger "END $($myinvocation.mycommand)"
    }
}

function join-esxHostToActiveDirectory {
<#
   .Synopsis
        This function Join an ESXi Host to Active Directory 
    .Description
        This function Join an ESXi Host to Active Directory
     .Parameter ESXServers 
        List of esx servers to join to active directory
     .Parameter DomainName
        Domain to join
     .Parameter DomainUser
        Admin User on the domain
   .Example
        join-esxHostToActiveDirectory -EsxServers host1,host2 -DomainName=domain.local -DomainUser administrator@domain.local
   .Example
        join-esxHostToActiveDirectory -EsxServers host -DomainName=domain.local -DomainUser administrator@domain.local

#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)][ValidateNotNullorEmpty()][String[]]$ESXServers,
        [ValidateNotNullorEmpty()][String]$DomainName,
        [ValidateNotNullorEmpty()][String]$DomainUser
    )


    begin {
        #Show-MyLogger "Starting $($myinvocation.mycommand)"
        $ADCreds=(Get-Credential -Message "Active Directory Credentials" -UserName $DomainUser)
        if ( $ADCreds -eq $null ) { 
            Show-MyLogger "Aborted..."
            break 
        }

    }
    process {
        foreach ( $esxi in $ESXServers) {
            try {
                $ErrorActionPreference='Stop'
                $esxcreds=(Get-Credential -Message "Enter $($esxi) credentials" -UserName root)
                if ($esxcreds -ne $null) {
                    Show-MyLogger "Connecting to $esxi"
                    Connect-VIServer $esxi -Credential $esxcreds -WarningAction SilentlyContinue |Out-Null
                    Show-MyLogger "Join $esxi to Active Directory Domain $DomainName"
                    Get-VMHostAuthentication |Set-VMHostAuthentication -Domain $DomainName -JoinDomain -Credential $ADCreds -Confirm:$false | Out-Null
                    disconnect-viserver $esxi -confirm:$false
                } else {
                    Show-MyLogger "Aborted..."
                }
            } catch { 
                Write-Warning $_.Exception.message
            }
        }
    }
    end {
        #Show-MyLogger "END $($myinvocation.mycommand)"
    }
}
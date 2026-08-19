Import-Module ActiveDirectory

$adminOU = "OU=AdminAccounts,OU=NordSystems,DC=corp,DC=nordsystems,DC=com"
$serviceOU = "OU=ServiceAccounts,OU=NordSystems,DC=corp,DC=nordsystems,DC=com"

$accounts = @(
    @{
        Sam="adm-mhalvorsen"
        Display="Max Halvorsen - Privileged"
        Type="Privileged"
        Path=$adminOU
        Group="GG_Admin_Infrastructure"
        Description="Privileged account for domain and server administration"
    },
    @{
        Sam="adm-amenon"
        Display="Adi Menon - Privileged"
        Type="Privileged"
        Path=$adminOU
        Group="GG_Admin_Infrastructure"
        Description="Privileged account for workstation and GLPI administration"
    },
    @{
        Sam="svc-backup"
        Display="Veeam Backup Service"
        Type="Service"
        Path=$serviceOU
        Group="GG_Svc_Backup"
        Description="Backup repository and guest-processing service identity"
    },
    @{
        Sam="svc-glpi"
        Display="GLPI LDAP Service"
        Type="Service"
        Path=$serviceOU
        Group="GG_Svc_Application"
        Description="Read-only LDAP bind identity for GLPI"
    },
    @{
        Sam="svc-dhcp"
        Display="DHCP DNS Update Service"
        Type="Service"
        Path=$serviceOU
        Group="GG_Svc_Application"
        Description="Secure dynamic DNS update identity used by DHCP"
    },
    @{
        Sam="svc-samba"
        Display="Samba Integration Service"
        Type="Service"
        Path=$serviceOU
        Group="GG_Svc_Application"
        Description="Service identity supporting NS-FS01 Active Directory integration"
    }
)

foreach ($account in $accounts) {
    $existing = Get-ADUser `
        -Filter "SamAccountName -eq '$($account.Sam)'"

    if (-not $existing) {
        $password = Read-Host `
            "Enter a unique password for $($account.Sam)" `
            -AsSecureString

        New-ADUser `
            -Name $account.Display `
            -DisplayName $account.Display `
            -SamAccountName $account.Sam `
            -UserPrincipalName "$($account.Sam)@nordsystems.com" `
            -Path $account.Path `
            -Description $account.Description `
            -AccountPassword $password `
            -Enabled $true

        if ($account.Type -eq "Privileged") {
            Set-ADUser `
                -Identity $account.Sam `
                -ChangePasswordAtLogon $true
        }
        else {
            Set-ADUser `
                -Identity $account.Sam `
                -PasswordNeverExpires $true `
                -CannotChangePassword $true
        }

        Write-Host "Created: $($account.Sam)" -ForegroundColor Green
    }
    else {
        Write-Host "Exists: $($account.Sam)" -ForegroundColor Yellow
    }

    $directMember = Get-ADGroupMember -Identity $account.Group |
        Where-Object { $_.SamAccountName -eq $account.Sam }

    if (-not $directMember) {
        Add-ADGroupMember `
            -Identity $account.Group `
            -Members $account.Sam

        Write-Host `
            "Added $($account.Sam) to $($account.Group)" `
            -ForegroundColor Cyan
    }
}

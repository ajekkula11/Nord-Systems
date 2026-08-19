Import-Module ActiveDirectory

$tempPassword = Read-Host `
    "Enter a temporary password of at least 14 characters" `
    -AsSecureString

$users = @(
    @{
        First="Abhi"; Last="Rao"; Display="Abhi Rao"; Sam="arao"
        ID="NS-101"; Department="Administration"; Title="Managing Director"
        OU="Administration"; Manager=$null
        Groups=@("GG_Dept_Administration","GG_Tier_Executive","GG_Owner_Administration")
    },
    @{
        First="Jay"; Last="Patel"; Display="Jay Patel"; Sam="jpatel"
        ID="NS-102"; Department="Administration"; Title="Administrative Assistant"
        OU="Administration"; Manager="arao"
        Groups=@("GG_Dept_Administration","GG_Tier_Staff")
    },
    @{
        First="Sarah"; Last="Whitfield"; Display="Sarah Whitfield"; Sam="swhitfield"
        ID="NS-103"; Department="Finance"; Title="Finance Manager"
        OU="Finance"; Manager="arao"
        Groups=@("GG_Dept_Finance","GG_Tier_Manager","GG_Owner_Finance")
    },
    @{
        First="Joe"; Last="Brennan"; Display="Joe Brennan"; Sam="jbrennan"
        ID="NS-104"; Department="Finance"; Title="Accounts Payable Specialist"
        OU="Finance"; Manager="swhitfield"
        Groups=@("GG_Dept_Finance","GG_Tier_Staff")
    },
    @{
        First="Anna"; Last="Lindqvist"; Display="Anna Lindqvist"; Sam="alindqvist"
        ID="NS-105"; Department="Human Resources"; Title="HR Manager"
        OU="HumanResources"; Manager="arao"
        Groups=@("GG_Dept_HR","GG_Tier_Manager","GG_Owner_HR")
    },
    @{
        First="Emma"; Last="Sørensen"; Display="Emma Sørensen"; Sam="esorensen"
        ID="NS-106"; Department="Human Resources"; Title="HR Coordinator"
        OU="HumanResources"; Manager="alindqvist"
        Groups=@("GG_Dept_HR","GG_Tier_Staff")
    },
    @{
        First="Max"; Last="Halvorsen"; Display="Max Halvorsen"; Sam="mhalvorsen"
        ID="NS-107"; Department="Information Technology"; Title="Systems Administrator"
        OU="IT"; Manager="arao"
        Groups=@("GG_Dept_IT","GG_Tier_Manager","GG_Owner_IT")
    },
    @{
        First="Adi"; Last="Menon"; Display="Adi Menon"; Sam="amenon"
        ID="NS-108"; Department="Information Technology"; Title="IT Support Technician"
        OU="IT"; Manager="mhalvorsen"
        Groups=@("GG_Dept_IT","GG_Tier_Staff")
    },
    @{
        First="Ruby"; Last="Castellanos"; Display="Ruby Castellanos"; Sam="rcastellanos"
        ID="NS-109"; Department="Marketing"; Title="Marketing Lead"
        OU="Marketing"; Manager="arao"
        Groups=@("GG_Dept_Marketing","GG_Tier_Manager","GG_Owner_Marketing")
    },
    @{
        First="Lexi"; Last="Novak"; Display="Lexi Novak"; Sam="lnovak"
        ID="NS-110"; Department="Marketing"; Title="Marketing Associate"
        OU="Marketing"; Manager="rcastellanos"
        Groups=@("GG_Dept_Marketing","GG_Tier_Staff")
    }
)

$departmentBase = "OU=Departments,OU=NordSystems,DC=corp,DC=nordsystems,DC=com"

foreach ($user in $users) {
    $existing = Get-ADUser -Filter "SamAccountName -eq '$($user.Sam)'"

    if (-not $existing) {
        New-ADUser `
            -Name $user.Display `
            -DisplayName $user.Display `
            -GivenName $user.First `
            -Surname $user.Last `
            -SamAccountName $user.Sam `
            -UserPrincipalName "$($user.Sam)@nordsystems.com" `
            -EmailAddress "$($user.Sam)@nordsystems.com" `
            -EmployeeID $user.ID `
            -Department $user.Department `
            -Title $user.Title `
            -Path "OU=$($user.OU),$departmentBase" `
            -HomeDrive "H:" `
            -HomeDirectory "\\NS-FS01\Home$\$($user.Sam)" `
            -AccountPassword $tempPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "Created: $($user.Sam)" -ForegroundColor Green
    }
    else {
        Write-Host "Exists: $($user.Sam)" -ForegroundColor Yellow
    }

    foreach ($group in $user.Groups) {
        $directMember = Get-ADGroupMember -Identity $group |
            Where-Object { $_.SamAccountName -eq $user.Sam }

        if (-not $directMember) {
            Add-ADGroupMember -Identity $group -Members $user.Sam
            Write-Host "Added $($user.Sam) to $group" -ForegroundColor Cyan
        }
    }
}

# Set managers after all accounts exist
foreach ($user in $users) {
    if ($user.Manager) {
        Set-ADUser -Identity $user.Sam -Manager $user.Manager
    }
}

[cmdletbinding()]
Param(
    [switch]$install = $false
)

$SiteCode = ''
$RSATPath = ''
$domain = ''

# install RSAT tools and AD Powershell modules
Function Install-ADModule{
    $RSATInstalled = Get-WmiObject -Class Win32_QuickFixEngineering -Property HotFixID | where HotFixId -eq 'KB958830'
    if(-not $RSATInstalled){
        # install RSAT Hotfix
        if((Get-WmiObject -Class win32_processor).addresswidth -eq 64){
            start-process "C:windows\system32\wusa.exe" -argumentlist "$RSATPATH\Windows6.1-KB958830-x64-RefreshPkg.msu" -wait
        } else {
            start-process "C:windows\system32\wusa.exe" -argumentlist "$RSATPATH\Windows6.1-KB958830-x86-RefreshPkg.msu" -wait
        }

    }

    # Enable Powershell AD Module
    dism /online /enable-feature /featurename:RemoteServerAdministrationTools
    dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles
    dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles-AD
    dism /online /enable-feature /featurename:RemoteServerAdministrationTools-Roles-AD-Powershell
}

######################################################################################################################
#
# Version 1.0
#  Date: 7/27/2015
#  Author: Joe Bugni
#
######################################################################################################################
# Query-ADUser
#    Wrapper for Get-ADUser
#    Can search using partial name. Will use wildcard to expand
#    Parameters:
#      UserName - specify to search by username. If identifier is provided, will search by username. Case insensitive
#       Ex: Query-ADUser jbugni or Query-ADUser -username jbugni
#      LastName - specify to search by lastname. LastName or Username should be specified for best results.
#      FirstName - Specify to search by first name. If first name and last name are used, both must be in result. 
#       Ex: Query-ADUser -LastName Bugni -FirstName Joseph
######################################################################################################################
Function Query-ADUser{
    Param(
        [Parameter(Position=1)]
        [string]$UserName = '',
        [string]$LastName = '',
        [string]$FirstName = ''
    )

    # check if username was supplied
    if($UserName.Length){
        $temp = "*$userName*"
        $users = Get-ADUser -filter {samaccountname -like $temp} -Properties samaccountname,office,EmailAddress,OfficePhone,CN

    } else {
        $tempLast = "$LastName*"
        $tempFirst = "$FirstName*"
        $users = Get-ADUser -filter {(surname -like $tempLast) -and (givenName -like $tempFirst)} -Properties samaccountname,office,EmailAddress,OfficePhone,CN
    }

    # empty array for storing hash table of users
    $Fullinfo = @()

    # SCCM Console required, and modules must be loaded and must be in SCCM PSDrive
    $cwd = pwd
    Set-Location $SiteCode
    foreach($user in $users){
        $PrimaryDevices = Get-UserDevices -Username $user.samaccountname
        
        # Create custom object for storing user info
        $hash = New-Object PSObject -Property @{
            EmployeeName = $user.CN
            Username = $user.samaccountname
            Email = $user.emailaddress
            Phone = $user.officephone
            Location = $user.office
            PrimaryDevices = $PrimaryDevices.Name
        }
        $Fullinfo += $hash
    }
    #$FullInfo | Format-Table -AutoSize -Property EmployeeName,Username,Location,Email,Phone,PrimaryDevices
    Set-Location $cwd
    Return $Fullinfo
}

##################################################################################
# Function Get-UserDevices
#      Query for UserDeviceAffinity relationships and resolve with computer names
##################################################################################
Function Get-UserDevices{
    Param(
        [string]$Username
    )
    $cwd = pwd
    Set-Location $SiteCode
    $PrimaryDevices = Get-CMUserDeviceAffinity -UserName "$domain\$Username" | ForEach-Object{ Get-CMDevice -Id $_.ResourceID | select Name}
    Set-Location $cwd
    Return $PrimaryDevices
}

Function Get-PrimaryUser{
    Param(
        [string]$ComputerName
    )
    $cwd = pwd
    Set-Location $SiteCode
    $PrimaryUsers = Get-CMUserDeviceAffinity -DeviceName $ComputerName | ForEach-Object {Get-CMUser -Name $_.UniqueUserName }
    Set-Location $cwd
    Return $PrimaryUsers.SMSID
}



##############
# TODO
##############

## Set UserDeviceAffinity
#Add-CMUserAffinityToDevice -DeviceName mn001cpwkjbngpn -UserName 'domain\username'
# return something?
function Set-DeviceAffinity{
    Param(
        [string]$Username,
        [string]$ComputerName
    )
    $cwd = pwd
    Set-Location $SiteCode
    Add-CMUserAffinityToDevice -DeviceName $ComputerName -UserName "$domain\$Username" 
    Set-Location $cwd
}


## Remove UserDeviceAffinity
#Remove-CMUserAffinityFromDevice -UserName 'chsinc\jbugni99' -DeviceName mn001cpwkjbngpn
# return something?
function Remove-UserDeviceAffinity{
    Param(
        [string]$Username,
        [string]$ComputerName
    )
    $cwd = pwd
    Set-Location $SiteCode
    Remove-CMUserAffinityFromDevice -UserName "chsinc\$Username" -DeviceName $ComputerName
    Set-Location $cwd
}

## query primary devices for user collection

function Get-PrimaryDevicesForUserCollection{
    Param(
        [string]$UserCollection
    )
    $cwd = pwd
    Set-Location $SiteCode
    $members = Get-CMUser -CollectionName $UserCollection
    # ##TODO -> Return as object
    $list = @()
    foreach($member in $members){
        $hash = New-Object PSObject -Property @{
            Name = $member.Name
            UserName = $member.SMSID
            Devices = (Get-CMUserDeviceAffinity -UserName $member.SMSID).ResourceName
        }
        $list += $hash
    }
    Set-Location $cwd
    return $list
}


## Add Collection Rules 
function Add-DeviceToCollectionDirectMembership{
        Param(
            [string]$DeviceCollection,
            [string]$ComputerName
        )
        $cwd = pwd
        Set-Location $SiteCode
        Add-CMDeviceCollectionDirectMembershipRule -CollectionName "$DeviceCollection" -ResourceId (Get-CMDevice -Name $ComputerName).ResourceID
        Set-Location $cwd
}


################################################################################
# NEEDS WORK
#
# if install parameter selected, install RSAT hotfix (if needed) and AD module
if($install){
    Install-ADModule
} else {
    try{
        Import-Module ActiveDirectory
    } catch{ 
        Write-Output "You must install the AD Powershell Modules first. Open new powershell window as Administrator, and launch script using -install parameter"
        Install-ADModule
    }
    
    if(Test-Path 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'){
        Import-Module 'C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
    } elseif(Test-Path 'C:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1') {
        Import-Module 'C:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
    } else { Write-Output 'Configuration Manager Console must be installed on this computer to find Primary Devices. This must be done manually' }
}

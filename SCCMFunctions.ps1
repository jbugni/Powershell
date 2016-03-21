[cmdletbinding()]
Param()

Import-Module -Name ActiveDirectory
Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace("\bin\i386","\bin\configurationmanager.psd1") 
# import configuration
[xml]$config = Get-Content -Path "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\config.xml"

$SiteCode = $config.settings.SiteCode
$domain = $config.settings.Domain
$PrimarySiteServer = $config.settings.PrimarySiteServer


######################################################################################################################
#
# Version 1.0
#  Date: 7/27/2015
#  Author: Joe Bugni
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
<#

.SYNOPSIS
Wrapper for Get-ADUser. Can search using partial name. Will use wildcard to expand
.DESCRIPTION
Wrapper for Get-ADUser. Can search using partial name. Will use wildcard to expand
.PARAMETER UserName
a single username. Default parameter if none is specified
.PARAMETER LastName
a single Last Name used when searching for user
.PARAMETER FirstName
a single First Name used when searching for a user. Use in conjunction with LastName to narrow results

#>
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
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    foreach($user in $users){
        $PrimaryDevices = Get-UserDevices -Username $user.samaccountname
        
        # Create custom object for storing user info
        $hash = New-Object -TypeName PSObject -Property @{
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
    Set-Location -Path $cwd
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
    # parse out domain from username
    $Username = $Username -replace ("$domain\\",'')

    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    $PrimaryDevices = Get-CMUserDeviceAffinity -UserName "$domain\$Username" | ForEach-Object{ Get-CMDevice -Id $_.ResourceID | Select-Object -Property Name}
    Set-Location -Path $cwd
    Return $PrimaryDevices
}

Function Get-PrimaryUser{
    Param(
        [string]$ComputerName
    )
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    $PrimaryUsers = Get-CMUserDeviceAffinity -DeviceName $ComputerName | ForEach-Object {Get-CMUser -Name $_.UniqueUserName }
    Set-Location -Path $cwd
    Return $PrimaryUsers.SMSID
}

## Set UserDeviceAffinity
#Add-CMUserAffinityToDevice -DeviceName MININT-00U5PK -UserName 'domain\username'
# return something?
function Set-DeviceAffinity{
    Param(
        [string]$Username,
        [string]$ComputerName
    )
    # parse out domain from username
    $Username = $Username -replace ("$domain\\",'')
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    Add-CMUserAffinityToDevice -DeviceName $ComputerName -UserName "$domain\$Username" 
    Set-Location -Path $cwd
}


## Remove UserDeviceAffinity
#Remove-CMUserAffinityFromDevice -UserName 'domain\user' -DeviceName MININT-00U5PK
function Remove-UserDeviceAffinity{
    Param(
        [string]$Username,
        [string]$ComputerName
    )
    # parse out domain from username
    $Username = $Username -replace ("$domain\\",'')
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    Remove-CMUserAffinityFromDevice -UserName "$domain\$Username" -DeviceName $ComputerName
    Set-Location -Path $cwd
}

## query for primary devices for user collection
function Get-PrimaryDevicesForUserCollection{
    Param(
        [string]$UserCollection
    )
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    $members = Get-CMUser -CollectionName $UserCollection
    # ##TODO -> Return as object
    $list = @()

    foreach($member in $members){
        $UserDevices = (Get-CMUserDeviceAffinity -UserName $member.SMSID).ResourceName
        foreach($UserDevice in $UserDevices){
            # create separate hash for each device to avoid system.object[] went exporting to csv
            $hash = New-Object -TypeName PSObject -Property @{
                Name = $member.Name
                UserName = $member.SMSID -replace ("$domain\\",'')
                Device = $UserDevice # (Get-CMUserDeviceAffinity -UserName $member.SMSID).ResourceName 
            }
            $list += $hash
        }
    }
    Set-Location -Path $cwd
    return $list
}

# query for primary user by providing a list of comptuer names, 1 per line
function Get-PrimaryUsersForDeviceList{
    Param(
        [string]$File
    )
    $list = Get-Content -Path $File
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    $devices = @()
    foreach($item in $list){
        $device = Get-CMDevice -Name $item
        $devices += $device
    }
    $list = @()

    foreach($device in $devices){
        # create separate hash for each device to avoid system.object[] went exporting to csv
        $hash = New-Object -TypeName PSObject -Property @{
            UserName = $device.UserName
            Device = $device.Name # (Get-CMUserDeviceAffinity -UserName $member.SMSID).ResourceName 
        }
        $list += $hash
    }
    Set-Location -Path $cwd
    return $list
}

# retrieve primary user for devices based on a device collection
function Get-PrimaryUsersForDeviceCollection{
    Param(
        [string]$DeviceCollection
    )
    $cwd = Get-Location
    Set-Location -Path "$($SiteCode):"
    $devices = Get-CMDevice -CollectionName $DeviceCollection
    # ##TODO -> Return as object
    $list = @()

    foreach($device in $devices){
        # create separate hash for each device to avoid system.object[] went exporting to csv
        $hash = New-Object -TypeName PSObject -Property @{
            UserName = $device.UserName
            Device = $device.Name # (Get-CMUserDeviceAffinity -UserName $member.SMSID).ResourceName 
        }
        $list += $hash
    }
    Set-Location -Path $cwd
    return $list
}


## Add Collection Rules 

function Add-DeviceToCollectionDirectMembership{
        Param(
            [string]$DeviceCollection,
            [string]$ComputerName
        )
        $cwd = Get-Location
        Set-Location -Path "$($SiteCode):"
        Add-CMDeviceCollectionDirectMembershipRule -CollectionName "$DeviceCollection" -ResourceId (Get-CMDevice -Name $ComputerName).ResourceID
        Set-Location -Path $cwd
}


# Get Collection stuff
function Get-CollectionsForDevice{
        Param(
            [string]$ComputerName
        )
        $cwd = Get-Location
        Set-Location -Path "$($SiteCode):"
        $ResID = (Get-CMDevice -Name $ComputerName).ResourceID
        $Collections = (Get-WmiObject -computername $PrimarySiteServer -Class sms_fullcollectionmembership -Namespace "root\sms\site_$($SiteCode.Substring(0,3))" -Filter "ResourceID = '$($ResID)'").CollectionID
        foreach ($Collection in $Collections)
        {
            Get-CMDeviceCollection -CollectionId $Collection | Select-Object -Property Name, CollectionID
        }
        Set-Location -Path $cwd
}

# one name per line
function Build-UserCollectionFromList{
        Param(
            [Parameter(Mandatory=$true)]
            [string]$File,
            [Parameter(Mandatory=$true)]
            [string]$CollectionName
        )
   $cwd = Get-Location
   Set-Location -Path "$($SiteCode):"
   $users = Get-Content -Path $File
   foreach($user in $users){
       # parse out domain from username
       $user = $user -replace ("$domain\\",'')
       Add-CMUserCollectionDirectMembershipRule -CollectionName "$CollectionName" -ResourceId (Get-CMUser -Name "$domain\$user").ResourceID
   }
   Set-Location -Path $cwd
}

# one computer name per line
function Build-DeviceCollectionFromList{
        Param(
            [Parameter(Mandatory=$true)]
            [string]$File,
            [Parameter(Mandatory=$true)]
            [string]$CollectionName
        )
   $cwd = Get-Location
   Set-Location -Path "$($SiteCode):"
   $devices = Get-Content -Path $File
   foreach($device in $devices){
       Add-CMDeviceCollectionDirectMembershipRule -CollectionName "$CollectionName" -ResourceId (Get-CMDevice -Name $device).ResourceID
   }
   Set-Location -Path $cwd
}
[cmdletbinding()]
Param()
[xml]$config = Get-Content -Path "$(Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)\config.xml"

function Add-UserToGroup{
    Param(
        #[Parameter(Mandatory=$true)]
        [string]$Domain=$($config.Settings.Domain),
        [Parameter(Mandatory=$true)]
        [string]$Username,
        [Parameter(Mandatory=$true)]
        [string]$LocalGroup
    )
    $objUser = [ADSI]("WinNT://$domain/$Username")
    $objGroup = [ADSI]("WinNT://./$LocalGroup")
    $objGroup.PSBase.Invoke("Add",$objUser.PSBase.Path)
}

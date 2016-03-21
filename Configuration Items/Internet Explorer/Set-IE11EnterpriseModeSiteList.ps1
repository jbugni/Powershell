function Discover-IE11EnterpriseModeSiteList{
    $SiteList = 'https://someurl.com/EnterpriseMode.xml'
    if(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode'){
        if((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode' -Name SiteList -ErrorAction SilentlyContinue) -match $SiteList){
            "Compliant"
        } else {
            "Non-Compliant"
        }
    } else {
        "Non-Compliant"
    }
}

function Remediate-IE11EnterpriseModeSiteList{
    $SiteList = 'https://someurl.com/EnterpriseMode.xml'
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode' -ErrorAction SilentlyContinue
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode' -Name SiteList -Value $SiteList -Force
}
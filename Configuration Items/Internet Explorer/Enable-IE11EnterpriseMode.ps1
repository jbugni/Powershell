function Discover-IE11EnableEnterpriseMode{
    if(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode'){
        # exists
        if(Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode' -Name Enable -ErrorAction SilentlyContinue){
            # EP Enabled
            "Compliant"
        } else {
            # not enabled
            "Non-Compliant"
        }
    } else {
        "Non-Compliant"
    }
}

function Remediate-IE11EnableEnterpriseMode{
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode' -ErrorAction SilentlyContinue
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main\EnterpriseMode' -Name Enable -Force
}
function Discover-O365AutoUpgradeDisabled{
    #office 2013
    if(Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\15.0\common\officeupdate'){
        $UpgradeCheck = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Office\15.0\common\officeupdate' -Name enableautomaticupgrade -ErrorAction SilentlyContinue
            if ($UpgradeCheck.enableautomaticupgrade -eq 0)
                {Write-Host 'Compliant'}
            else
                {Write-Host 'Non-Compliant'}      
                 
    #office 2016
    } elseif (Test-Path 'HKLM:\SOFTWARE\Policies\Microsoft\Office\16.0\common\officeupdate'){
            $UpgradeCheck = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Office\15.0\common\officeupdate' -Name enableautomaticupgrade -ErrorAction SilentlyContinue
            if ($UpgradeCheck.UpdatesEnabled -eq 0)
                {Write-Host 'Compliant'}
            else
                {Write-Host 'Non-Compliant'}
    } else { Write-Host 'Non-Compliant' }
}

function Remediate-O365AutoUpgradeDisabled{
    New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Office\15.0\common\officeupdate' -Force
    New-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Office\15.0\common\officeupdate' -Name enableautomaticupgrade -Value '0' -Type DWord -Force
}
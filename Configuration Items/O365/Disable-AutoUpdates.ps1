function Discover-O365DisableUpdates{
    #office 2013
    if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration'){
        $UpdateCheck = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration' -Name UpdatesEnabled
            if ($UpdateCheck.UpdatesEnabled -eq $True)
                {Write-Host 'Non-Compliant'}
            else
                {Write-Host 'Compliant'}       
    #office 2016
    } elseif (Test-Path 'HKLM:\SOFTWARE\Microsoft\Office\16.0\ClickToRun\Configuration'){
            $UpdateCheck = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\16.0\ClickToRun\Configuration' -Name UpdatesEnabled
            if ($UpdateCheck.UpdatesEnabled -eq $True)
                {Write-Host 'Non-Compliant'}
            else
                {Write-Host 'Compliant'}
    }
}

function Remediate-Discovery-O365DisableUpdates{
    if(Test-Path 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration'){
        Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration' -Name UpdatesEnabled -Value 'False' -Force
    } elseif (Test-Path 'HKLM:\SOFTWARE\Microsoft\Office\16.0\ClickToRun\Configuration'){
        Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\16.0\ClickToRun\Configuration' -Name UpdatesEnabled -Value 'False' -Force
    }
}
function Discover-O365EnableCloudUpdates{
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration'
    if((Get-ItemProperty -Path $registryPath -Name 'UpdatesEnabled' -ErrorAction SilentlyContinue).UpdatesEnabled -eq 'True'){
        if(Get-ItemProperty -Path $registryPath -Name 'UpdateURL' -ErrorAction SilentlyContinue){
            'Non-Compliant'
        } else {
            'Compliant'
        }
    } elseif ((Test-Path $registryPath) -eq $false){
        'Compliant'
    } else { 'Non-Compliant' }
}

function Remediate-O365EnableCloudUpdates{
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration'
    New-ItemProperty -Path $registryPath -Name 'UpdatesEnabled' -Value 'True' -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $registryPath -Name 'UpdateURL' -Force -ErrorAction SilentlyContinue
}

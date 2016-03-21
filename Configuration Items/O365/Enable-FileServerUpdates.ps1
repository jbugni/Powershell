function Discover-O365EnableFileServerUpdates{
    $UpdateServer = 'FILESERVER1'
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration'
    if((Get-ItemProperty -Path $registryPath -Name 'UpdatesEnabled' -ErrorAction SilentlyContinue).UpdatesEnabled -eq 'True'){
        if((Get-ItemProperty -Path $registryPath -Name 'UpdateURL' -ErrorAction SilentlyContinue).UpdateURL -eq "\\$UpdateServer\O365\Prod"){
            'Compliant'
        } else {
            'Non-Compliant'
        }
    } elseif ((Test-Path $registryPath) -eq $false){
        'Compliant'
    } else { 'Non-Compliant' }
}

function Remediate-O365EnableFileServerUpdates{
    $UpdateServer = 'FILESERVER1'
    $registryPath = 'HKLM:\SOFTWARE\Microsoft\Office\15.0\ClickToRun\Configuration'
    New-ItemProperty -Path $registryPath -Name 'UpdatesEnabled' -Value 'True' -Force
    New-ItemProperty -Path $registryPath -Name 'UpdateURL' -Value "\\$UpdateServer\O365\Prod" -Force
}
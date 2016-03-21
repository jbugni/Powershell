function Discover-IEDisableEOLNotification{
    $compliant1 = $false
    # 64-bit and 32-bit
    if((Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_DISABLE_IE11_SECURITY_EOL_NOTIFICATION' -Name 'iexplore.exe' -ErrorAction SilentlyContinue).'iexplore.exe' -eq '1'){ $compliant1 = $true }
    else { $compliant1 = $false }
    
    # 64-bit
    $compliant2 = $false
    if ([System.IntPtr]::Size -eq 8) { 
        if((Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_DISABLE_IE11_SECURITY_EOL_NOTIFICATION' -Name 'iexplore.exe' -ErrorAction SilentlyContinue).'iexplore.exe' -eq '1'){ $compliant2 = $true }
        else { $compliant2 = $false }
        if(($compliant1 -eq $true) -and ($compliant2 -eq $true)){ "Compliant" }
        else { "Non-Compliant" }
    } else{ 
        if($compliant1 -eq $true){ "Compliant" }
        else { "Non-Compliant" }  
    }
}

function Remediate-IEDisableEOLNotification{
    New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_DISABLE_IE11_SECURITY_EOL_NOTIFICATION'
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_DISABLE_IE11_SECURITY_EOL_NOTIFICATION' -Name 'iexplore.exe' -PropertyType dword -Value '1'
    
    if ([System.IntPtr]::Size -eq 8) {
        New-Item -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_DISABLE_IE11_SECURITY_EOL_NOTIFICATION'
        New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_DISABLE_IE11_SECURITY_EOL_NOTIFICATION' -Name 'iexplore.exe' -PropertyType dword -Value '1'
    }
}
[CmdletBinding()]
Param (
    [ValidateSet("Install","Uninstall")] 
    [string] $DeploymentType = "Install",
    [ValidateSet("Interactive","Silent","NonInteractive")]
    [string] $DeployMode = "Interactive",
    [switch] $AllowRebootPassThru = $false
)

#*===============================================
#* VARIABLE DECLARATION
Try {
#*===============================================
## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
#*===============================================
# Variables: Application

$appVendor = "Citrix"
$appName = "Citrix Receiver"
$appVersion = "14.2.100.14"
$appArch = ""
$appLang = "EN"
$appRevision = "01"
$appScriptVersion = "1.0.0"
$appScriptDate = "06/26/2015"
$appScriptAuthor = "Joe Bugni"

#*===============================================
# Variables: Script - Do not modify this section

$deployAppScriptFriendlyName = "Deploy Application"
$deployAppScriptVersion = "3.0.7"
$deployAppScriptDate = "10/24/2013"
$deployAppScriptParameters = $psBoundParameters

# Variables: Environment
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
# Dot source the App Deploy Toolkit Functions
."$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"

#*===============================================
#* END VARIABLE DECLARATION
#*===============================================

#*===============================================
#* PRE-INSTALLATION
If ($deploymentType -ne "uninstall") { $installPhase = "Pre-Installation"
#*===============================================

    # Close open service based on Citrix Article CTX137494 (http://support.citrix.com/article/CTX137494)
    Show-InstallationWelcome -CloseApps "iexplore,ssonsvr,SelfServicePlugin,Receiver" -Silent
    
    # Show Progress Message (with the default message)
    Show-InstallationProgress
    
    Execute-Process -Path "$dirFiles\Clean.bat" 
    Execute-Process -Path "$dirFiles\RCU.exe" -Parameters '/silent'
	
    	
#*===============================================
#* INSTALLATION 
$installPhase = "Installation"
#*===============================================
	
    Execute-Process -FilePath "$dirFiles\CitrixReceiver.exe" -Arguments "/silent /includeSSON ENABLE_SSON=yes ALLOWADDSTORE=A STARTMENUDIR=`"CHS Inc. Citrix Applications`" LEGACYFTAICONS=True ADDLOCAL=ReceiverInside,ICA_Client,SSON,AM,SELFSERVICE,USB,DesktopViewer,Flash,Vd3d"


#*===============================================
#* POST-INSTALLATION
$installPhase = "Post-Installation"
#*===============================================

    # Perform post-installation tasks here
   
    #CHS Changes
    If (([environment])::Is64BitOperatingSystem -eq $true) {
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Wow6432Node\Citrix\AuthManager " -Name "ConnectionSecurityMode" -Value Any -Type string
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Wow6432Node\Policies\Citrix " -Name "EnableFTU" -Value 0 -Type Dword
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Wow6432Node\Citrix\Dazzle " -Name "UseCategoryAsStartMenuPath" -Value True -Type string
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Policies\Citrix\ICA Client\SSON " -Name "Enable" -Value True -Type string
    }Else{
        #32bit Keys
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Citrix\AuthManager " -Name "ConnectionSecurityMode" -Value Any -Type string
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Policies\Citrix " -Name "EnableFTU" -Value 0 -Type Dword
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Citrix\Dazzle " -Name "UseCategoryAsStartMenuPath" -Value True -Type string
        Set-RegistryKey -Key "HKLM:\SOFTWARE\Policies\Citrix\ICA Client\SSON " -Name "Enable" -Value True -Type string
    }
    #Set Citrix Version Number for SCCM Detection	
	
    Set-RegistryKey -Key "HKLM\SOFTWARE\Citrix\Receiver" -Name "Version" -Value $appVersion -Type string
	
	#Group Policy Update	
	Update-GroupPolicy
	
    # Set Registry Keys to prevent Citrix Receiver from Updating
    Set-RegistryKey -Key "HKLM\SOFTWARE\Citrix\Receiver" -Name "AutoUpdatesEnabled" -Value 0 -Type DWord
    Set-RegistryKey -Key "HKLM\SOFTWARE\Citrix\Receiver" -Name "AutoUpdate" -Value 1 -Type DWord
    Set-RegistryKey -Key "HKLM\SOFTWARE\Citrix\Receiver" -Name "ShowIcon" -Value 0 -Type DWord
    
    # Create Active Setup to prevent AutoUpdate
    Copy-File -Path "$dirSupportFiles\CU-DisableCitrixUpdate.cmd" -Destination "$envWindir\Installer\CU-DisableCitrixUpdate.cmd"
    Set-RegistryKey -Key "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableCitrixAutoUpdate" -Name "DisableCitrixAutoUpdate" -Value "DisableCitrixAutoUpdate" -Type String
    Set-RegistryKey -Key "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableCitrixAutoUpdate" -Name "ComponentID" -Value "DisableCitrixAutoUpdate" -Type String
    Set-RegistryKey -Key "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableCitrixAutoUpdate" -Name "Version" -Value "2013,11,20,1" -Type String
    Set-RegistryKey -Key "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableCitrixAutoUpdate" -Name "StubPath" -Value "$envWindir\Installer\CU-DisableCitrixUpdate.cmd" -Type String
    Set-RegistryKey -Key "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableCitrixAutoUpdate" -Name "Locale" -Value "EN" -Type String
    
    Set-RegistryKey -Key "HKCU\Software\Citrix\Receiver" -Name "AutoUpdatesEnabled" -Value 0 -Type DWord
    Set-RegistryKey -Key "HKCU\Software\Citrix\Receiver" -Name "AutoUpdate" -Value 1 -Type DWord
    Set-RegistryKey -Key "HKCU\Software\Citrix\Receiver" -Name "ShowIcon" -Value 0 -Type DWord
    
    # Close open service based on Citrix Article CTX137494 (http://support.citrix.com/article/CTX137494)
    Show-InstallationWelcome -CloseApps "iexplore,ssonsvr,selfserviceplugin,Receiver" -Silent
    
    
 
#*===============================================
#* UNINSTALLATION
} ElseIf ($deploymentType -eq "uninstall") { $installPhase = "Uninstallation"
#*===============================================

    # Close open service based on Citrix Article CTX137494 (http://support.citrix.com/article/CTX137494)
    Show-InstallationWelcome -CloseApps "iexplore,ssonsvr,selfserviceplugin,receiver" -Silent
    
    # Show Progress Message (with the default message)
    Show-InstallationProgress
    
    # Remove this version of Citrix Receiver
    Execute-Process -FilePath "$dirFiles\Clean.bat" -Arguments "/silent"
    
    #Remove Citrix Version Number for SCCM Detection	
    Remove-RegistryKey -Key "HKLM\SOFTWARE\Citrix\Receiver" -Name "Version"
    
    Remove-RegistryKey -Key "HKLM\SOFTWARE\Microsoft\Active Setup\Installed Components\DisableCitrixAutoUpdate"
    Remove-File -Path "$envWindir\Installer\CU-DisableCitrixUpdate.cmd"
    
#*===============================================
#* END SCRIPT BODY
} } Catch {$exceptionMessage = "$($_.Exception.Message) `($($_.ScriptStackTrace)`)"; Write-Log "$exceptionMessage"; Show-DialogBox -Text $exceptionMessage -Icon "Stop"; Exit-Script -ExitCode 1} # Catch any errors in this script 
Exit-Script -ExitCode 0 # Otherwise call the Exit-Script function to perform final cleanup operations
#*===============================================

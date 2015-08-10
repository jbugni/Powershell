function List-UserProfiles(){
    [cmdletbinding()]
    param
    (
    	[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    	$ComputerName = $env:COMPUTERNAME
    )        
    $ErrorActionPreference = 'SilentlyContinue'
    
    # grab all profiles on computer
    $Profiles = Get-WmiObject -Class Win32_UserProfile -Computer $ComputerName -ErrorAction 0
    foreach ($Profile in $Profiles)
    {
        # skip built-in accounts
    	if(-not ($Profile.localpath -like 'C:\Windows\*')) {
    		$objSID = New-Object System.Security.Principal.SecurityIdentifier($Profile.sid)
    		$objuser = $objSID.Translate([System.Security.Principal.NTAccount])
    		$ProfileList = New-Object -TypeName PSobject
    		$ProfileList | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.toUpper()
    		$ProfileList | Add-Member -MemberType NoteProperty -Name ProfileName -Value $objuser.value
    		$ProfileList | Add-Member -MemberType NoteProperty -Name ProfilePath -Value $Profile.localpath
    		$ProfileList
    	}
    }
}

function Get-Uptime(){
    [cmdletbinding()]
    param
    (
    	[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    	$ComputerName = $env:computername
    )  
    Get-WmiObject -ComputerName $ComputerName win32_operatingsystem | select @{LABEL='ComputerName'; EXPRESSION={$_.csname}}, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}
}
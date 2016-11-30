<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.130
	 Created on:   	2016/11/28 15:04
	 Created by:   	wang,xinyan@hpe【xinyanw@hpe.com】
	 Organization: 	HPE I&A
	 Filename:     	profile
	===========================================================================
	.DESCRIPTION
		Change default password for users
#>
#####################################################
#Logic Block 1:               | Log Logical
#LogError: 	                  | ErrorLog Function
#LogDebug：                   | DebugLog Function
#LogInfo：                    | InfoLog Function
#####################################################
$scriptpath = $MyInvocation.MyCommand.Definition
#Write-Host $scriptpath
$parentpath = Split-Path -Parent $scriptpath
$logfile = $parentpath + "\changepassword.log"
Function write2log($logentry)
{
	if (Test-Path $logfile)
	{
		#do nothing
	}
	else
	{
		try
		{
			New-Item $logfile -type file -force
		}
		catch
		{
			
		}
	}
	
	try
	{
		$logentry | out-file -Filepath $logfile -force -Append -Encoding ASCII
	}
	catch
	{
		Start-Sleep -m (Get-Random -minimum 30 -maximum 50)
		try
		{
			$logentry | out-file -Filepath $logfile -force -Append -Encoding ASCII
		}
		catch
		{
			Start-Sleep -m (Get-Random -minimum 150 -maximum 200)
			try
			{
				$logentry | out-file -Filepath $logfile -force -Append -Encoding ASCII
			}
			catch { }
		}
	}
}

Function LogError($action, $errmsg)
{
	$dt = Get-Date
	$dtstr = $dt.ToString()
	
	$logentry = "[$($dtstr)]|[ERROR] - [$($action)] $($errmsg)"
	write2log($logentry)
}


Function LogInfo($infomsg)
{
	$dt = Get-Date
	$dtstr = $dt.ToString()
	
	$logentry = "[$($dtstr)]|[INFO] - $($infomsg)"
	write2log($logentry)
}

################################################################################
#Logic Block 2:               |Main Logic
#description：Write the password in script and make username as parameter
################################################################################
Import-Module ActiveDirectory
$pass = ConvertTo-SecureString -AsPlainText Porsche911 -Force

#$adminMembers = net localgroup administrators

if ($args.Length -eq 0)
{
	Write-Host -ForegroundColor Red "Please input username who need to change password"
	LogError "No username has been input"
	return $null
}
else
{
#	try 
#	{
		set-adaccountpassword $username -Reset -NewPassword $pass
		Set-ADUser $username -ChangePasswordAtLogon $true
		Write-Host -ForegroundColor Green "password has been reset to Porsche911"
		LogInfo "password of $($username) has been reset to Porsche911"
<#	}
	catch
	{
		Write-Host -ForegroundColor Red "Name Error"
		LogInfo "Name $($username) Error"
	}#>
	
}
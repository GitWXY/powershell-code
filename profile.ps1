<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.130
	 Created on:   	2016/11/16 15:04
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
Set-ExecutionPolicy UnRestricted
[string]$xmldocpath = "c:\adminlist.xml"

$xmlDoc = New-Object "system.xml.xmldocument"
$xmlDoc.Load($xmldocpath)
$nodeList = $xmlDoc.GetElementsByTagName("AdminList");
foreach ($node in $nodeList)
{
	$childNodes = $node.ChildNodes
	$Admins = $childNodes.Item(0).InnerXml.ToString()
	$AdminArray = $Admins.split("|")
}

#$adminMembers = net localgroup administrators

if ($args.Length -eq 0)
{
	Write-Host -ForegroundColor Red "Please input username who need to change password"
	LogError "No username has been input"
	return $null
}
else
{
	# username:    script parameter
	# useraccount: the username check from the enviroment
	$script:n = 0
	$script:username = $args[0]
	#$script:useraccount = (Get-WmiObject -Class Win32_UserAccount -Filter "Name='$env:username'").name
	$script:useraccount = $env:username
	#当当前用户修改的是自己的密码时
	if ($username -eq $useraccount)
	{
		#遍历系统管理员名单，如果自己是系统管理员，则禁止修改密码
		foreach ($Admin in $AdminArray)
		{
			if ($useraccount -eq $Admin)
			{
				#当前用户是系统管理员，直接禁止修改密码并跳出遍历
				Write-Host -ForegroundColor Yellow "Can not change the password of administrator"
				LogInfo "password of $($username) can not be changed"
				$n = 0
				break
			}
			else
			{
				#当前用户目前还不是系统管理员，继续遍历
				LogInfo "$($Admin) is administrator, you are not this admin"
				$n = 1
			}
		}
		#遍历结束，n不为0, 表示用户不是系统管理员，可以修改自己的密码
		if ($n -ne 0)
		{
			set-adaccountpassword $username -Reset -NewPassword $pass
			Write-Host -ForegroundColor Green "password has been reset to Porsche911"
			LogInfo "password of $($username) has been reset to Porsche911"	
		}
		
	}
	#当前用户修改的不是自己的密码时
	else
	{
		$script:m = 0
		#遍历管理员列表
		:mainloop foreach ($Admin in $AdminArray)
		{
			Write-Host -ForegroundColor Yellow "$($Admin) and $($useraccount)"
			#当前用户是管理员时，可以修改除其它管理员以外的用户密码
			if ($useraccount -eq $Admin)
			{
				:secloop foreach ($Admin in $AdminArray)
				{
					#所需要修改密码的用户也是管理员
					if ($username -eq $Admin)
					{
						Write-Host -ForegroundColor Yellow "Can not change the password of administrator"
						LogInfo "password of $($username) can not be changed"
						$m = 0
						break mainloop
					}
					#所需要修改密码的用户还不是管理员，继续遍历
					else
					{
						Write-Host -ForegroundColor Yellow "$($Admin) is administrator, you are not this admin"
						LogInfo "$($Admin) is administrator, you are not this admin"
						$m = 1
						
					}
				}
				break mainloop
			}
			
			#当前用户不是管理员，则不允许修改密码
			else
			{
				Write-Host -ForegroundColor Red "This is not your adaccount, you can not change it's password"
				LogInfo "$($useraccount) has no access to change the password of $($username)"
				$m = 0
			}
		}
		#遍历结束，m 不为 0 时，所需要修改密码的用户一直不是管理员，则可以修改密码
		if ($m -ne 0)
		{
			try
			{
				set-adaccountpassword $username -Reset -NewPassword $pass
				Write-Host -ForegroundColor Green "password has been reset to Porsche911"
				LogInfo "password of $($username) has been reset to Porsche911"
			}
			catch
			{
				Write-Host -ForegroundColor Red "Name Error"
				LogInfo "Name $($username) Error"
			}
			
		}
		
	}
	
}
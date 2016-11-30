#######################################################################################################
#
#[NAME]:    HPE-System get backup file to pcn
#[PURPOSE]:
#检测源服务器cnsheimsap03上的文件夹是否有上个月的文件
#如有新文件产生则将目录中的文件复制到cnshlpcnfs03上【ASKPI和GLKPI分别在不同的目录】
#
# [AUTHOR]:  Wang,Xinyan@hpe
#            xinyanw@hpe.com
#
#
# [VERSION HISTORY]:
#   0.1  11/15/2016 - Wang,Xinyan - Initial release
#
#######################################################################################################

############################################
#Logic Block 1:               | 日志逻辑模块
#LogError: 	                  | 错误日志方法
#LogDebug：                   | 调试日志方法
#LogInfo：                    | 信息日志方法
############################################
$scriptpath = $MyInvocation.MyCommand.Definition
Write-Host $scriptpath
$parentpath = Split-Path -Parent $scriptpath
$logfile = $parentpath + "\getfile.log"
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

#############################################
#Logic Block 2:      	| 筛选符合条件的文件
#############################################
$nowtimeyear = get-date -Format 'yyyy'
$nowtimemonth = get-date -Format 'MM'

#源服务器文件夹地址【脚本所在服务器】
$fromfilepath = "X:\RVS\KPI_OUT\Backup"

#获取源服务器文件夹下子文件夹个数
$folderCount = Get-ChildItem -Path X:\RVS\KPI_OUT\Backup -Force | Where-Object { $_.PSIsContainer -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
if ($folderCount -eq 0)
{
	Write-Host "There is no sub folder in this folder"
	LogInfo "There is no sub folder in this folder"
}
else
{
	Write-Host "Start to filter sub folders"
	LogInfo "Start to filter sub folders"
	$newfolder = "D:\tempfolder"
	New-Item  $newfolder -type directory
	Get-ChildItem $fromfilepath | ForEach-Object -Process {
		if ($_ -is [System.IO.DirectoryInfo])
		{
			$foldername = $_.name
			
			$foldernameStr = $foldername.Substring(6, 7)
			$foldernameArray = $foldernameStr -split "-"
			$foleryear = $foldernameArray[0]
			write-host $foleryear
			
			if ($nowtimeyear -eq $foleryear)
			{
				
				$foldermonth = $foldernameArray[1]
				$diffmonth = $nowtimemonth - 1
				if ($diffmonth -lt 10)
				{
					$diffmonth = -Join ("0", $diffmonth)
				}
				if ($foldermonth -eq $diffmonth)
				{
					$type = $foldername.substring(0, 5)
					if ($type -eq "ASKPI")
					{
						$backupfolder = $newfolder + "\ASKPIback\"+$foldername
					}
					else
					{
						$backupfolder = $newfolder + "\GLKPIback\"+$foldername
					}
					$allfile = $fromfilepath + "\" + $foldername + "\*.*"
					New-Item $backupfolder -type directory
					Copy-Item $allfile $backupfolder
				}
			}
			else
			{
				Write-Host $foleryear.GetType() $nowtimeyear.GetType()
			}
		}
	}
}
############################################
#Logic Block 3:      	| 读取参数文件并复制文件
############################################

Write-Host "Start to copy files to destination"
LogInfo "Start to copy files to destination"

$localDirPathASKPI = "D:\tempfolder\ASKPIback"
$localDirPathGLKPI = "D:\tempfolder\GLKPIback"
$remoteDirPathASKPI = "P:\Aftersales Department\KPI"
$remoteDirPathGLKPI = "P:\Network Management and Development Department\KPI 2.0"


Get-ChildItem $localDirPathASKPI | ForEach-Object -Process {
	if ($_ -is [System.IO.DirectoryInfo])
	{
		$folderASKPI = $_.name
		$remoteNewFolderASKPI = $remoteDirPathASKPI + "\" + $folderASKPI
		$filesAS = Get-ChildItem -Path $folderASKPI # 获取本地目录下的文件
		foreach ($fileAS in $filesAS)
		{
			Copy-Item -Path $fileAS.FullName -Destination $remoteNewFolderASKPI
			write-host $file.FullName
		}
	}
}
Remove-Item $localDirPathASKPI -Recurse

Get-ChildItem $localDirPathGLKPI | ForEach-Object -Process {
	if ($_ -is [System.IO.DirectoryInfo])
	{
		$folderGLKPI = $_.name
		$remoteNewFolderGLKPI = $remoteDirPathGLKPI + "\" + $folderGLKPI
		$filesGL = Get-ChildItem -Path $folderGLKPI # 获取本地目录下的文件
		foreach ($fileGL in $filesGL)
		{
			Copy-Item -Path $fileGL.FullName -Destination $remoteNewFolderGLKPI
			write-host $file.FullName
		}
	}
}
Remove-Item $localDirPathGLKPI -Recurse
#$filesAS = Get-ChildItem -Path $localDirPathASKPI # 获取本地目录下的文件







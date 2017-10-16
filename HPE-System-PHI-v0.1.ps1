#######################################################################################################
#
# [NAME]:    HPE-System Powershell script3
#
#[PURPOSE]:
#定时检测本地服务器【Porsche_Holding_Interface】是否有新文件产生
#如有新文件产生则将目录剪切到指定目录中【E:\PHIBAK】下
#
# [AUTHOR]:  Wang,Xinyan@hpe
#            xinyanw@hpe.com
#
#
# [VERSION HISTORY]:
#   0.1  10/19/2016 - Wang,Xinyan - Initial release
#	0.2  10/24/2016 - Wang,Xinyan - Change detecting files to detecting folders
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
$script:cfgfilepath = $parentpath + "\HPE-System.cfg"
$logfile = $parentpath + "\HPE-System.log"
Function write2log($logentry)
{
	if(Test-Path $logfile) {
		#do nothing
	} else	{
		try {
			New-Item $logfile -type file -force
		} catch {
		
		}
	}
	
	try {
		$logentry | out-file -Filepath $logfile -force -Append -Encoding ASCII
	} catch {
		Start-Sleep -m (Get-Random -minimum 30 -maximum 50)
		try {
			$logentry | out-file -Filepath $logfile -force -Append -Encoding ASCII
		} catch {
			Start-Sleep -m (Get-Random -minimum 150 -maximum 200)
			try {
				$logentry | out-file -Filepath $logfile -force -Append -Encoding ASCII
			} catch {}
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

Function LogDebug($debugmsg)
{
	if ($debug -eq 0)
	{
		return $null
	}
	
	$dt = Get-Date
	$dtstr = $dt.ToString()
	
	$logentry = "[$($dtstr)]|[DEBUG] - $($debugmsg)"
	
	write2log($logentry)
}

Function LogInfo($infomsg)
{
	$dt = Get-Date
	$dtstr = $dt.ToString()
	
	$logentry = "[$($dtstr)]|[INFO] - $($infomsg)"
	write2log($logentry)
}
##########################################
#Logic Block 2:      	| 读取参数文件逻辑
#read_cfg: 	            | 读取参数文件方法
##########################################
$script:catalognames = ""
$script:filenames = ""
Function read_cfg($filename)
{
	LogInfo "Start Reading config file"
    Write-Host -ForegroundColor Green $filename
	$lines = get-content $filename -ReadCount 0
	foreach($line in $lines) {
		if($line -match "^#"){continue}
		if($line -match "^\s*;"){continue}
		
		$param = $line.split("=",2)
        
		switch ($param[0])
		{
           
			"host_name_PHI"
			{
				$script:hostname = $param[1]
                
			}
			<#'catalog_name_PHI'
			{
				$script:catalognames = $param[1]
			}
			'file_name_PHI'
			{
				$script:filenames = $param[1]
			}#>
			'back_path_PHI'
			{
				$script:back_path = $param[1]
			}
			'debug'
			{
				$script:debug = $param[1]
			}
            
		}
	}
}
###############################################
#Logic Block 3:|通过参数文件检测相应路径新文件
#
###############################################


LogInfo "Start detect new files in HPE-System"

if(Test-Path $cfgfilepath) {
	read_cfg($cfgfilepath)
	#$catalognameArray = $catalognames.split("|")
	#$filenameArray = $filenames.split("|")
	#$serverbakpath = Set-Location $back_path_2
    $serverbakpath = $back_path
	#foreach ($catalogname in $catalognameArray) {
	$serverfilepath = "\\"+$hostname+"\Porsche_Holding_Interface"
		LogInfo "Start to detect new files in $($serverfilepath)"
		#foreach ($filename in $filenameArray) {
		$folderCount = Get-ChildItem -Path \\DCFIleServer\Porsche_Holding_Interface\ -Force | Where-Object { $_.PSIsContainer -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
		if($folderCount -eq 0) {
			LogInfo "There is no sub folder in this folder"
		} else {
			LogInfo "Found sub folder and will start to backup one by one"
			Get-ChildItem $serverfilepath | ForEach-Object -Process{
				if($_ -is [System.IO.DirectoryInfo]){
					Write-Host($_.name)
					$catalogname = $_.name
					$serverfolder = $serverfilepath+'\'+$catalogname
					LogInfo "Found new folder 【$($serverfolder)】 and start to backup"
					if(Test-Path $serverbakpath) {
						try {
							$nowtime = Get-Date -Format 'yyyy-MM-dd-HH-mm'
                 
							$serverbak = $serverbakpath+"\"+$catalogname+"_"+$nowtime
							Write-Host -ForegroundColor Yellow $serverbak
							if(Test-Path $serverbak){
                      
								Write-Host -ForegroundColor Yellow $serverbak					    
							} else {
								New-Item $serverbak -type directory
							}
							Write-Host -ForegroundColor Red $serverfolder
							$serverAllfile = $serverfolder+"\*.*"
							Copy-Item $serverAllfile $serverbak
							try {
								LogInfo "backup successfully and delete 【$($filename)】"
								Remove-Item $serverAllfile #TBD
							} catch {}
										
						} catch {
							LogError "backup failed"
						}
					} else {
						LogInfo "Can not find backup path and will make one"
						New-Item $serverbakpath -type directory
						try {
							LogInfo "Create file directory successfully and start to backup"
							$nowtime = Get-Date -Format 'yyyy-MM-dd-HH-mm'
					 
							$serverbak = $serverbakpath+"\"+$catalogname+"_"+$nowtime
							if(Test-Path $serverbak){
								Write-Host -ForegroundColor Yellow $serverbak					    
							} else {
								New-Item $serverbak -type directory
							}
							Write-Host -ForegroundColor Red $serverfolder
							$serverAllfile = $serverfolder+"\*.*"
							Copy-Item $serverAllfile $serverbak
							try {
								LogInfo "BACKUP successfully and delete 【$($filename)】"
								Remove-Item $serverAllfile #TBD
							} catch {}
							
							
						} catch {}
					}
				}
			}
		}
			
		#}
	#}
	
} else {
	LogError "Can not find config file in this file path"
}



#######################################################################################################
#
# [NAME]:    HPE-System Powershell script
#
#[PURPOSE]:
#定时检测本地服务器指定目录是否有新文件产生，如有新文件产生则将目录备份到指定目录中【E:\ToDealerBAK】并将检测
#文件复制到所有的【Dealer No】目录下
#
# [AUTHOR]:  Wang,Xinyan@hpe
#            xinyanw@hpe.com
#
#
# [VERSION HISTORY]:
#   0.1  10/12/2016 - Wang,Xinyan - Initial release
#	0.2  10/14/2016 - Wang,Xinyan - change 【copy file】 to 【copy the whole directory】
#	0.3  10/24/2016 - Wang,Xinyan - change backup path to local path/change dealer_no config to mutiple
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
           
			"host_name_PI"
			{
				$script:hostname = $param[1]
                
			}
			'catalog_name_PI'
			{
				$script:catalognames = $param[1]
			}
			'file_name_PI'
			{
				$script:filenames = $param[1]
			}
            'back_path_PI'
            {
                $script:back_path = $param[1]
            }
            'PI_des_path'
            {
                $script:des_path = $param[1]
                
            }
			'dealer_no'
			{
				$script:dealernos = $param[1]
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
	$catalognameArray = $catalognames.split("|")
	$filenameArray = $filenames.split("|")
    $dealernoArray = $dealernos.split("|")
	$serverbakpath = $back_path
	$serverdes = "\\"+$hostname+"\"+$des_path
	foreach ($catalogname in $catalognameArray) {
		$serverfilepath = "\\"+$hostname+"\"+$catalogname
		LogInfo "Start to detect new files in $($serverfilepath)"
		foreach ($filename in $filenameArray) {
			$serverfilename = $serverfilepath+"\"+$filename
            Write-Host -ForegroundColor Yellow $serverfilename
			if(Test-Path $serverfilename) {
				LogInfo "Found new files 【$($filename)】 and start to backup"
				if(Test-Path $serverbakpath) {
					try {
						$nowtime = Get-Date -Format 'yyyy-MM-dd'
                 
						$serverbak = $serverbakpath+"\"+$catalogname+"_"+$nowtime
                        if(Test-Path $serverbak){
                            Write-Host -ForegroundColor Yellow $serverbak					    
                        } else {
                            New-Item $serverbak -type directory
                        }
                        Write-Host -ForegroundColor Red $serverfilepath
                        $serverAllfile = $serverfilepath+"\*.*"
                        Copy-Item $serverAllfile $serverbak
                        
						if(Test-Path $serverdes) {
							try {
								LogInfo "backup successfully and start to copy 【$($filename)】"
							    foreach ($dealerno in $dealernoArray) {
                                    $serverdespath = $serverdes+'\'+$dealerno
                                    if(Test-Path $serverdespath) {
                                        LogInfo "Found the destination path $($serverdespath)"
                                        Copy-Item $serverfilename -destination $serverdespath
                                    }else{
                                        LogInfo "Cannot find the destination path and will create one"
                                        New-Item $serverdespath -type directory
                                        Copy-Item $serverfilename -destination $serverdespath
                                    }
                                }
								
								try {
									LogInfo "Copy successfully and delete 【$($filename)】"
									#Remove-Item $serverfilename #TBD
								} catch {}
							} catch {
								LogError "Copy Failed"
							}
						} else {
							LogInfo "Can not find copy path and will make one"
							New-Item $serverdespath -type directory
							try {
								LogInfo "create $($serverdespath) successfully and start to copy file"
								Copy-Item $serverfilename -destination $serverdespath
								try {
									LogInfo "Copy successfully and delete 【$($filename)】"
									#Remove-Item $serverfilename #TBD
								} catch {}
							} catch {
								LogError "Copy failed"
							}
						}					
					} catch {
						LogError "backup failed"
					}
				} else {
					LogInfo "Can not find backup path and will make one"
					New-Item $serverbakpath -type directory
					try {
						LogInfo "Create file directory successfully and start to backup"
						$nowtime = Get-Date -Format 'yyyy-MM-dd'
                 
						$serverbak = $serverbakpath+"\"+$catalogname+"_"+$nowtime
                        if(Test-Path $serverbak){
                            Write-Host -ForegroundColor Yellow $serverbak					    
                        } else {
                            New-Item $serverbak -type directory
                        }
                        Write-Host -ForegroundColor Red $serverfilepath
                        $serverAllfile = $serverfilepath+"\*.*"
                        Copy-Item $serverAllfile $serverbak
						if(Test-Path $serverdespath) {
							try {
								LogInfo "backup successfully and start to copy 【$($filename)】"
							
								Copy-Item $serverfilename -destination $serverdespath
								try {
									LogInfo "Copy successfully and delete 【$($filename)】"
									#Remove-Item $serverfilename #TBD
								} catch {}
							} catch {
								LogError "Copy Failed"
							}
						} else {
							LogInfo "Can not find copy path and will make one"
							New-Item $serverdespath -type directory
							try {
								LogInfo "create $($serverdespath) successfully and start to copy file"
								Copy-Item $serverfilename -destination $serverdespath
								try {
									LogInfo "Copy successfully and delete 【$($filename)】"
									#Remove-Item $serverfilename #TBD
								} catch {}
							} catch {
								LogError "Copy failed"
							}
						}
						
					} catch {}
				}
                
				
			} else {
				LogInfo "Can not found any new files"
			}
		}
	}
	
} else {
	LogError "Can not find config file in this file path"
}



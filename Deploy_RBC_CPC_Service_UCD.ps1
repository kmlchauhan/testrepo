    Import-Module bitstransfer
	
	function PowerShell-PrintErrorCodes ($strReturnCode)
	{
	#This function will print the right value. The error code list was extracted using the MSDN documentation for the change method
	Switch ($strReturnCode) 
		{
		0{ write-host  "    0 The request was accepted." -foregroundcolor "white" -BackgroundColor "darkgreen" } 
		1{ write-host  "    1 The request is not supported." -foregroundcolor "white" -BackgroundColor "Red" } 
		2{ write-host  "    2 The user did not have the necessary access."-foregroundcolor "white" -BackgroundColor "Red"} 
		3{ write-host  "    3 The service cannot be stopped because other services that are running are dependent on it." -foregroundcolor "white" -BackgroundColor "Red"} 
		4{ write-host  "    4 he requested control code is not valid, or it is unacceptable to the service." -foregroundcolor "white" -BackgroundColor "Red"} 
		5{ write-host  "    5 The requested control code cannot be sent to the service because the state of the service (Win32_BaseService State property) is equal to 0, 1, or 2." -foregroundcolor "white" -BackgroundColor "Red"} 
		6{ write-host  "    6 The service has not been started." -foregroundcolor "white" -BackgroundColor "Red"} 
		7{ write-host  "    7 The service did not respond to the start request in a timely fashion." -foregroundcolor "white" -BackgroundColor "Red"} 
		8{ write-host  "    8 Unknown failure when starting the service."-foregroundcolor "white" -BackgroundColor "Red" } 
		9{ write-host  "    9 The directory path to the service executable file was not found." -foregroundcolor "white" -BackgroundColor "Red"} 
		10{ write-host  "    10 The service is already running."-foregroundcolor "white" -BackgroundColor "Red" } 
		11{ write-host  "    11 The database to add a new service is locked."-foregroundcolor "white" -BackgroundColor "Red" } 
		12{ write-host  "    12 A dependency this service relies on has been removed from the system."-foregroundcolor "white" -BackgroundColor "Red" } 
		13{ write-host  "    13 The service failed to find the service needed from a dependent service."-foregroundcolor "white" -BackgroundColor "Red" } 
		14{ write-host  "    14 The service has been disabled from the system."-foregroundcolor "white" -BackgroundColor "Red" } 
		15{ write-host  "    15 The service does not have the correct authentication to run on the system."-foregroundcolor "white" -BackgroundColor "Red" } 
		16{ write-host  "    16 This service is being removed from the system."-foregroundcolor "white" -BackgroundColor "Red" }
		17{ write-host  "    17 The service has no execution thread." -foregroundcolor "white" -BackgroundColor "Red"} 
		18{ write-host  "    18 The service has circular dependencies when it starts."-foregroundcolor "white" -BackgroundColor "Red" } 
		19{ write-host  "    19 A service is running under the same name."-foregroundcolor "white" -BackgroundColor "Red" } 
		20{ write-host  "    20 The service name has invalid characters."-foregroundcolor "white" -BackgroundColor "Red" } 
		21{ write-host  "    21 Invalid parameters have been passed to the service."-foregroundcolor "white" -BackgroundColor "Red" } 
		22{ write-host  "    22 The account under which this service runs is either invalid or lacks the permissions to run the service."-foregroundcolor "white" -BackgroundColor "Red" } 
		23{ write-host  "    23 The service exists in the database of services available from the system."-foregroundcolor "white" -BackgroundColor "Red" } 
		24{ write-host  "    24 The service is currently paused in the system."-foregroundcolor "white" -BackgroundColor "Red" } 
		}
	}	
	
	function CopyFiles([string]$SourceFolder,[string]$DestinationFolder)
    {
		Robocopy.exe "$SourceFolder" "$DestinationFolder" /E /MT:10
	
		write-host "==> error code is $lastexitcode "
						
		if(($lastexitcode -ge 0) -and ($lastexitcode -le 15))               
		{
			Write-Host "==> Copy-Success"
		}                
		else 
		{
			write-host "==> Copy-Fail"
			exit 999
		}
	}
	function StartService($ServiceToInstall)
	{
		try
		{
			Write-Host "==> Starting Service $ServiceToInstall " -foregroundcolor "Yellow" 
			start-service "$ServiceToInstall" -ErrorAction Stop
			Start-Sleep -s 5
		}
		catch
		{
			if ( $error[0].Exception -match "Microsoft.PowerShell.Commands.ServiceCommandException")
			{
				Write-Host "==> $error[0].Exception" -foregroundcolor "white" -BackgroundColor "Red"
				Write-Host "==> $ServiceToInstall is not started...." -foregroundcolor "white" -BackgroundColor "Red" 
			}
			else
			{
				Write-Host "==> $ServiceToInstall is installed and started..." -foregroundcolor "white" -BackgroundColor "darkgreen"
			}
		}
	}
	
	function StopService($ServiceToInstall)
	{
		try
		{
			Write-Host "==> Stopping $ServiceToInstall...." -foregroundcolor "Yellow" 
			Stop-Service "$ServiceToInstall" -Verbose -Force -PassThru -ErrorAction Stop
			Start-Sleep -s 5
		}
		catch
		{
			Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message" -foregroundcolor "white" -BackgroundColor "Red" 
		}
	}
	
	function ChangLogOnAccount([string]$ServiceToInstall,[string]$DomainUserName,[string]$Password)
	{
		#Write-Host "==> Changing Log On Account for $ServiceToInstall" -foregroundcolor "Yellow"
		$LocalSrv1 = Get-WmiObject Win32_service -filter "name='$ServiceToInstall'"
		
		$Value = $LocalSrv1.Change($null,$null,$null,$null,$null,$false,"$DomainUserName","$Password")
		#Note: You can change the Log On back to the default by changing the last two values to:"Network Service",""
		
		if ($Value.ReturnValue -eq '0') 
		{
			write-host "==> LogOn Account is Changed" -foregroundcolor "white" -BackgroundColor "darkgreen"
			PowerShell-PrintErrorCodes ($Value.ReturnValue)
		}
		else 
		{
			write-host "==> LogOn Account is not Changed " -foregroundcolor "white" -BackgroundColor "Red"
			PowerShell-PrintErrorCodes ($Value.ReturnValue)
		}
	}
	
	
	
	#=====================================================================================
    #                        Main Execution Entry Point
    #=====================================================================================
    
	Write-host "`t`t`t`t"
    Write-host "Started:: WindowsServices - RBC_CPC_Service Installation !!!!" -foregroundcolor "Yellow" 
    Write-host
    Write-host Loading service details - "Deploy_RBC_CPC_Service_UCD.xml". 
	
	$root=split-path -parent $MyInvocation.MyCommand.Definition
	write-host "Root Path = " $root -foregroundcolor "Yellow" 
	$xml = [xml](get-content $root\Deploy_RBC_CPC_Service_UCD.xml)
	 
	$services = $xml.WindowsServicesDeployment.ServiceToInstall

	[int]$servicesCount = $services.childnodes.count
	write-host "count = " $servicesCount
	
	#$service = $serviceAttribute.Name

	Try
	  {
	  
		foreach ($serviceAttribute in $services.ChildNodes) 
		{
			$ServiceToInstall = $serviceAttribute.Name
			$PhysicalDirectoryPath = $serviceAttribute.PhysicalDirectoryPath
			$StartupType = $serviceAttribute.StartupType
			$ServiceStatus = $serviceAttribute.ServiceStatus
			$ExecutableName = $serviceAttribute.ExecutableName
			
			$SourceProjectName = $serviceAttribute.SourceProjectName
			$TargetProjectName = $serviceAttribute.TargetProjectName
			
			$SourceFolder = ".\" + $SourceProjectName
			$DestinationFolder = $PhysicalDirectoryPath +"\" + $TargetProjectName
			
			$WinServiceDeployEnv = $serviceAttribute.DeployEnv
			#$ConfigSourceFolder = ".\Configuration_Files\"+$WinServiceDeployEnv+"\"+"WindowsServices" +"\" + $SourceProjectName

			$InstallExecutableName = $DestinationFolder + "\" + $ExecutableName

			write-host $SourceFolder and $DestinationFolder and $InstallExecutableName -foregroundcolor "Yellow" 
			
			#$Domain=$serviceAttribute.Domain
			#$Username=$serviceAttribute.Username
			$DomainUserName = $serviceAttribute.DomainUserName
			$Password=$serviceAttribute.Password
			
			#$DomainUserName = $Domain + "\" + $Username
						
			Write-Host $DomainUserName
			
			#$InstallFlag = $serviceAttribute.Install
			
			#if ($InstallFlag.ToLower() -eq "yes")
			#{
				#Checking whether Windows Service is already installed
				#$WinService = Get-Service -Name "$ServiceToInstall" -ErrorAction SilentlyContinue
				$WinService = Get-Wmiobject -class win32_service -filter "Name='$ServiceToInstall'"
				Write-Host "$WinService...." -foregroundcolor "Yellow"
				$CountName= $WinService | measure-object -character | select -expandproperty characters
				Write-Host "Total Characters of the service is $CountName...." -foregroundcolor "Yellow"
				if($CountName -gt 0)
				{
					Write-Host "==> $ServiceToInstall is already installed" -foregroundcolor "Yellow"
					
					write-host "==> Checking Windows Service Status"
					
					$ServiceName=Get-Service -Name $ServiceToInstall

					if($ServiceName.Status -eq "Running")
					{
						Write-Host "==> $ServiceToInstall is Running ...." -foregroundcolor "Yellow" 
						try
						{
							Write-Host "==> Stopping $ServiceToInstall...." -foregroundcolor "Yellow" 
							Stop-Service "$ServiceToInstall" -Verbose -Force -PassThru -ErrorAction Stop
						}
						catch
						{
							 Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message" -foregroundcolor "white" -BackgroundColor "Red" 
						}
						
																	
						$InstalledServicePath1 = (Get-WmiObject -query "SELECT PathName FROM Win32_Service WHERE Name = '$ServiceToInstall'").PathName
						
						Write-Host "==> $ServiceToInstall installed location is $InstalledServicePath1.... " -foregroundcolor "Yellow"
						Write-Host $InstalledServicePath1 -foregroundcolor "Yellow"
						$InstalledServicePath1 = $InstalledServicePath1 -Replace """",''
						
						if($InstalledServicePath1 -eq "$InstallExecutableName")
						{
							write-host "Given Physical path is equals to already installed path " -foregroundcolor "Yellow"
							
							write-host "Copying the Files " -foregroundcolor "Yellow"
							CopyFiles $SourceFolder $DestinationFolder
							
							Write-Host "==> Changing Log On Account for $ServiceToInstall" -foregroundcolor "Yellow"
							ChangLogOnAccount $ServiceToInstall $DomainUserName $Password
							
							Write-Host "==> Setting the Startup type for $ServiceToInstall to $StartupType"  -foregroundcolor "Yellow" 
						    Set-Service "$ServiceToInstall" -startuptype "$StartupType"
							
							if ($ServiceStatus.ToLower() -eq "start")
							{
								StartService $ServiceToInstall
							}
							else
							{
								StopService $ServiceToInstall
							}
							
						}
						else
						{
							write-host "Given Physical path is not equals to already installed path " -foregroundcolor "Yellow"
							write-host "Hence, Un-installing the service which is already installed in different path" -foregroundcolor "Yellow"
							
							.\Install\InstallUtil.exe /u $InstalledServicePath1
						
						    Start-Sleep -s 10
							
							write-host "Copying the Files " -foregroundcolor "Yellow"
							CopyFiles $SourceFolder $DestinationFolder
							
							write-host "==> Installing $ServiceToInstall.... " -foregroundcolor "Yellow" 
							.\Install\InstallUtil.exe "$InstallExecutableName" /LogToConsole=true
							
							Write-Host "==> Changing Log On Account for $ServiceToInstall" -foregroundcolor "Yellow"
							ChangLogOnAccount $ServiceToInstall $DomainUserName $Password
							
							Write-Host "==> Setting the Startup type for $ServiceToInstall to $StartupType"  -foregroundcolor "Yellow" 
						    Set-Service "$ServiceToInstall" -startuptype "$StartupType"
							
							if ($ServiceStatus.ToLower() -eq "start")
							{
								StartService $ServiceToInstall
							}
							else
							{
								StopService $ServiceToInstall
							}
						}

					}

					if($ServiceName.Status -eq "Stopped")
					{
						$InstalledServicePath1 = (Get-WmiObject -query "SELECT PathName FROM Win32_Service WHERE Name = '$ServiceToInstall'").PathName
						
						Write-Host "==> $ServiceToInstall installed location is $InstalledServicePath1.... " -foregroundcolor "Yellow"
						Write-Host $InstalledServicePath1 -foregroundcolor "Yellow"
						$InstalledServicePath1 = $InstalledServicePath1 -Replace """",''
						
						if($InstalledServicePath1 -eq "$InstallExecutableName")
						{
							write-host "Given Physical path is equals to already installed path " -foregroundcolor "Yellow"
							
							write-host "Copying the Files " -foregroundcolor "Yellow"
							CopyFiles $SourceFolder $DestinationFolder
							
							Write-Host "==> Changing Log On Account for $ServiceToInstall" -foregroundcolor "Yellow"
							ChangLogOnAccount $ServiceToInstall $DomainUserName $Password
							
							Write-Host "==> Setting the Startup type for $ServiceToInstall to $StartupType"  -foregroundcolor "Yellow" 
						    Set-Service "$ServiceToInstall" -startuptype "$StartupType"
							
							if ($ServiceStatus.ToLower() -eq "start")
							{
								StartService $ServiceToInstall
							}
							else
							{
								StopService $ServiceToInstall
							}
							
						}
						else
						{
							write-host "Given Physical path is not equals to already installed path " -foregroundcolor "Yellow"
							write-host "Hence, Un-installing the service which is already installed in different path" -foregroundcolor "Yellow"
							
							.\Install\InstallUtil.exe /u $InstalledServicePath1
						
						    Start-Sleep -s 10
							
							write-host "Copying the Files " -foregroundcolor "Yellow"
							CopyFiles $SourceFolder $DestinationFolder
							
							write-host "==> Installing $ServiceToInstall.... " -foregroundcolor "Yellow" 
							.\Install\InstallUtil.exe "$InstallExecutableName" /LogToConsole=true
							
							Write-Host "==> Changing Log On Account for $ServiceToInstall" -foregroundcolor "Yellow"
							ChangLogOnAccount $ServiceToInstall $DomainUserName $Password
							
							Write-Host "==> Setting the Startup type for $ServiceToInstall to $StartupType"  -foregroundcolor "Yellow" 
						    Set-Service "$ServiceToInstall" -startuptype "$StartupType"
							
							if ($ServiceStatus.ToLower() -eq "start")
							{
								StartService $ServiceToInstall
							}
							else
							{
								StopService $ServiceToInstall
							}
						}
					}
				}
				else
				{
						Write-Host "==> $ServiceToInstall is not installed.... " -foregroundcolor "Yellow"
							
						write-host "Copying the Files " -foregroundcolor "Yellow"
						CopyFiles $SourceFolder $DestinationFolder
						
						write-host "==> Installing $ServiceToInstall.... " -foregroundcolor "Yellow" 
						.\Install\InstallUtil.exe "$InstallExecutableName" /LogToConsole=true
						
						Write-Host "==> Changing Log On Account for $ServiceToInstall" -foregroundcolor "Yellow"
						ChangLogOnAccount $ServiceToInstall $DomainUserName $Password
						
						Write-Host "==> Setting the Startup type for $ServiceToInstall to $StartupType"  -foregroundcolor "Yellow" 
						   Set-Service "$ServiceToInstall" -startuptype "$StartupType"
						
						if ($ServiceStatus.ToLower() -eq "start")
						{
							StartService $ServiceToInstall
						}
						else
						{
							StopService $ServiceToInstall
						}
							
				}
						
		}
			
	}
	  
	  catch
	  {
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foregroundcolor "white" -BackgroundColor "Red"
		Write-Host 
		exit 1
	  }
	  Finally
	  {
		$ServersCompleted | ForEach {
							write-host "   $_ .. Done"
						}
		write-host
	  }

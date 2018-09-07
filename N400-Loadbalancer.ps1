#=====================================================================================
# Param details 
# HealthCheck mode turn ON Execution command:: .\N400_LB.ps1 ON
# HealthCheck mode turn OFF Execution command:: .\N400_LB.ps1 OFF
# Mandatory paramter ==> ON/OFF
#===================================================================================== 
 

 
$Mode=$args[0]



function RenameHealthCheckFile ($fullPathWithFileNameHTTP,$HealthCheckFilePathHTTP,$HealthCheckFileName,$RenamedHealthCheckFileName)
{
	try
    {
write-host $fullPathWithFileNameHTTP
write-host $HealthCheckFilePathHTTP

	   if (Test-Path $fullPathWithFileNameHTTP)
			{
			
			Rename-Item $fullPathWithFileNameHTTP $RenamedHealthCheckFileName
			
				if(-not $?)               
				{
				write-host "Error in renaming the Original Health Check file $HealthCheckFileName to 

temporary file name $RenamedHealthCheckFileName, Exiting the process"
				exit 99
				}            
				else 
				{
				Write-Host "Original Health check file $HealthCheckFileName renamed to temporary Health 

check file name $RenamedHealthCheckFileName"
				sleep -s 10
				}
											
			}
		else
			{
			
			Write-host "Original Health check file $HealthCheckFileName not found on this server, So renaming to 

Temporary Health check file $RenamedHealthCheckFileName will not be done"
			
			
			
			}		 
    }
	catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foreground "Red"
        Write-Host 
        exit 1
    } 
}


function RevertHealthCheckFile ($RenamedfullPathWithFileNameHTTP,$HealthCheckFilePathHTTP,$HealthCheckFileName,$RenamedHealthCheckFileName)
{
	try
    {
        if (test-path $RenamedfullPathWithFileNameHTTP)
			{
			
			Rename-Item $RenamedfullPathWithFileNameHTTP $HealthCheckFileName
			
			if(-not $?)               
				{
				write-host "Error in renaming the Temporary Health Check file $RenamedHealthCheckFileName  

to Original Health check file $HealthCheckFileName, Exiting the process "
				exit 99
				}            
				else 
				{
				Write-Host "Temporary Health check file $RenamedHealthCheckFileName  renamed to Original 

Health check file $HealthCheckFileName "
				sleep -s 10
				}
			
			}
		else
			{
			
			Write-host "Temporary Health check file $RenamedHealthCheckFileName not found as Original Health 

check file $HealthCheckFileName is not renamed to Temporary Health check file $RenamedHealthCheckFileName " 
								
			}		 
    }
	catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foreground "Red"
        Write-Host 
        exit 1
    } 
}


function MaintenanceModeStart ($MaintenanceModeONExecutable,$MaintenanceModeTime)
{
	try
    {
        TEST-PATH $MaintenanceModeONExecutable
		write-host "Maintenance Mode ON Execuatable existence is $?"
		if ($?)
		{
			
			& cmd.exe /c $MaintenanceModeONExecutable $MaintenanceModeTime
			
			sleep -s 10
			
			if($lastexitcode -ne 0)               
				{
				write-host "Not able to start Maintenance mode, some error"
				exit 99
				}            
				else 
				{
				Write-Host "Maintenance mode Start"
				sleep -s 10
				}
			
			}
		else
			{
			
			Write-host "MaintenanceMode Executables not found on the server, Cannot place the server in 

maintenance mode " 
								
			}		 
    }
	catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foreground "Red"
        Write-Host 
        exit 1
    } 
}

function MaintenanceModeStop ($MaintenanceModeOFFExecutable,$MaintenanceModeTime)
{
	try
    {
        TEST-PATH $MaintenanceModeONExecutable
		write-host "Maintenance Mode OFF Execuatable existence is $?"
		if ($?)
		{
			& cmd.exe /c $MaintenanceModeOFFExecutable $MaintenanceModeTime
			
			sleep -s 10
			
			if($lastexitcode -ne 0)               
				{
				write-host "Not able to come out of Maintenance mode, some error"
				exit 99
				}            
				else 
				{
				Write-Host "Maintenance mode Stop"
				sleep -s 10
				}
			
			}
		else
			{
			
			Write-host "MaintenanceMode Executables not found on the server, Cannot take out this server from 

maintenance mode " 
								
			}		 
    }
	catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host  "==> Error, exiting ... : $_.Exception.Message" -foreground "Red"
        Write-Host 
        exit 1
    } 
}


#===================================================================================== 
#=====================================================================================
# Step 1. Load config data from .xml file   
#===================================================================================== 

Write-host "Started:: Load Balancer HealthCheck Process and Placing Server in Maintenance mode $Mode State"
write-host                                                                         
Write-host "Loading HealthCheck & Maintenance mode configuration details from - N400_LB.xml"
write-host                                                                       
write-host "Starting of Maintenance mode to $Mode State" 
write-host                                                                       	
	$root=split-path -parent $MyInvocation.MyCommand.Definition
	
	
	$xml = [xml](get-content $root\N400-Loadbalancer.xml)
	
	
	$HealthCheckFilePathHTTP=$xml.InfrastructureDetails.HealthCheckFilePath.HTTP
	
	$HealthCheckFileName=$xml.InfrastructureDetails.HealthCheckFileName
	
	$RenamedHealthCheckFileName=$xml.InfrastructureDetails.RenamedHealthCheckFileName
	
	$fullPathWithFileNameHTTP=$HealthCheckFilePathHTTP+"\"+$HealthCheckFileName	
	
	$RenamedfullPathWithFileNameHTTP=$HealthCheckFilePathHTTP+"\"+$RenamedHealthCheckFileName	
	
	$MaintenanceMode = $Mode
	
	$MaintenanceModeTime=$xml.InfrastructureDetails.MaintenanceModeTime 
	
	$MaintenanceModeONExecutable=$xml.InfrastructureDetails.MaintenanceModeONExecutable
	
	$MaintenanceModeOFFExecutable=$xml.InfrastructureDetails.MaintenanceModeOFFExecutable
	 
		
	write-host "Base directory path to Health check files is $HealthCheckFilePathHTTP"
	write-host ===================================================
	write-host                                                                         
	write-host "Original health check file name is $HealthCheckFileName"
	write-host ===================================================
	write-host                                                                         
	write-host "Temporary health check file name is $RenamedHealthCheckFileName"
	write-host ===================================================
	write-host                                                                         
	write-host "Path to the Original health check file is $fullPathWithFileNameHTTP"
	write-host ===================================================
	write-host                                                                         
	write-host "Path to the renamed health check file is $RenamedfullPathWithFileNameHTTP"
	write-host ===================================================
	write-host                                                                         
	write-host "Maintenance window state is $MaintenanceMode"
	write-host ===================================================
	write-host                                                                         
	write-host "Maintenance window time is $MaintenanceModeTime"
	write-host ===================================================
	write-host                                                                         
	write-host "Location of Maintenance Mode ON Executable : $MaintenanceModeONExecutable"
	write-host ===================================================
	write-host                                                                         
	write-host "Location of Maintenance Mode OFF Executable : $MaintenanceModeOFFExecutable"
	write-host ===================================================
	write-host                                                                         
	
	
	if ($MaintenanceMode -eq "ON")
	
	{
	
	MaintenanceModeStart $MaintenanceModeONExecutable $MaintenanceModeTime
		
	RenameHealthCheckFile $fullPathWithFileNameHTTP $HealthCheckFilePathHTTP $HealthCheckFileName $RenamedHealthCheckFileName
	
	}
	
	if ($MaintenanceMode -eq "OFF")
	
	{
	
	MaintenanceModeStop $MaintenanceModeONExecutable $MaintenanceModeTime
	
	RevertHealthCheckFile $RenamedfullPathWithFileNameHTTP $HealthCheckFilePathHTTP $HealthCheckFileName $RenamedHealthCheckFileName
	
	}
	
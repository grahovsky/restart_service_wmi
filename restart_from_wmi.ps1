#Set-ExecutionPolicy RemoteSigned

$server1c = 'localhost'
$agentPort = '1540'
$serviceName = '1C:Enterprise*'

function getWorkingProcessPID {
   
   $SrvAddr = $server1c + ":$agentPort"
   $ComObject = 'V83.ComConnector'

   try {
      $V83Com = New-Object -ComObject V83.COMConnector
      $ServerAgent = $V83Com.ConnectAgent($SrvAddr)
   }
   catch {
      throw $_.Exception.Message
   }

   $Clusters = $ServerAgent.GetClusters()

   $Cluster = $Clusters[0]
   $ServerAgent.Authenticate($Cluster, "", "")

   $WorkingProcesses = $ServerAgent.GetWorkingProcesses($Cluster);

   $pidArray = @()

   foreach ($WorkingProcess in $WorkingProcesses) {
      $pidArray += $WorkingProcess.PID
   }

   return $pidArray

}

function stopService {
   
   $remote_services = (Get-WmiObject -Class Win32_Service -ComputerName $server1c | Where-Object { $_.Name -match $serviceName -and $_.State -eq 'Running' })

   foreach ($remote_service in $remote_services) {
   
      $pidProcArray = getWorkingProcessPID
       
      $remote_service.StopService()
      sleep 10

      $remote_process = (Get-WmiObject -Class Win32_Process -ComputerName $server1c | Where-Object { $pidProcArray -contains $_.ProcessID })
      foreach ($remote_proces in $remote_process) {
         $win_proces.Terminate
      }
  
   }

   $remote_services = (Get-WmiObject -Class Win32_Service -ComputerName $server1c | Where-Object { $_.Name -match $serviceName -and $_.State -ne 'Stopped' })

   foreach ($remote_service in $remote_services) {
      
      $remote_pid = $remote_service.ProcessID    
      $remote_process = (Get-WmiObject -Class Win32_Process -ComputerName $server1c | Where-Object { $_.ProcessID -eq $remote_pid })
      foreach ($remote_proces in $remote_process) {
         $remote_proces.Terminate
      }
      
   }

}

function startService {

   $remote_services = (Get-WmiObject -Class Win32_Service -ComputerName $server1c | Where-Object { $_.Name -match $serviceName })

   foreach ($remote_service in $remote_services) {
      if ($remote_service.State -ne 'Running') {
         $remote_service.StartService()
         sleep 20
      }
   }

}

stopService
sleep 10
startService
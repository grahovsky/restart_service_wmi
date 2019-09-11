#Set-ExecutionPolicy RemoteSigned

$server1c = 'localhost'
$agentPort = '1540'
$serviceName = '1C:Enterprise\ 8\.3\ Server\ Agent'
$comObjectName = 'V83.COMConnector'

function getWorkingProcessPID {
   
   $SrvAddr = $server1c + ":$agentPort"

   try {
      $V83Com = New-Object -ComObject $comObjectName
      $ServerAgent = $V83Com.ConnectAgent($SrvAddr)
   }
   catch {
      throw $_.Exception.Message
   }

   $Clusters = $ServerAgent.GetClusters()

   $Cluster = $Clusters[0]
   $ServerAgent.Authenticate($Cluster, "", "")

   $Cluster.LifeTimeLimit = 30

   $ServerAgent.SetClusterRecyclingByTime($Cluster, $Cluster.LifeTimeLimit)
   $ServerAgent.SetClusterRecyclingExpirationTimeout($Cluster, 10)

   $WorkingProcesses = $ServerAgent.GetWorkingProcesses($Cluster);

   $pidArray = @()

   foreach ($WorkingProcess in $WorkingProcesses) {
      $pidArray += $WorkingProcess.PID
   }

   return $pidArray

}

function stopService {
   
   $remote_service = (Get-WmiObject -Class Win32_Service -ComputerName $server1c | Where-Object { $_.Name -match $serviceName -and $_.State -eq 'Running' })

   $pidProcArray = getWorkingProcessPID
      
   $remote_service.StopService()
   sleep 10

   $remote_processes = (Get-WmiObject -Class Win32_Process -ComputerName $server1c | Where-Object { $pidProcArray -contains $_.ProcessID })
   foreach ($remote_process in $remote_processes) {
      $win_process.Terminate
   }

   $remote_service = (Get-WmiObject -Class Win32_Service -ComputerName $server1c | Where-Object { $_.Name -match $serviceName -and $_.State -ne 'Stopped' })

   $remote_pid = $remote_service.ProcessID    
   $remote_processes = (Get-WmiObject -Class Win32_Process -ComputerName $server1c | Where-Object { $_.ProcessID -eq $remote_pid })
   foreach ($remote_process in $remote_processes) {
      $remote_process.Terminate
   }
      
}

function startService {

   $remote_service = (Get-WmiObject -Class Win32_Service -ComputerName $server1c | Where-Object { $_.Name -match $serviceName })

   if ($remote_service.State -ne 'Running') {
      $remote_service.StartService()
      sleep 20
   }

}

$pids1c = getWorkingProcessPID

# stopService
# sleep 10
# startService
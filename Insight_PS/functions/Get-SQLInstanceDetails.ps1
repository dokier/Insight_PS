<#
 .Synopsis
  Gets SQL Instance Details

 .Description
  Gets SQL Instance Details. This function queries InstanceDetails table on Insight database

 .Parameter Name
  Instance Name

 .Example
   # Serch for Instances with the name like 'SQLServer'
   Get-SQLInstanceDetails -Name 'SQLServer'
#>
function Get-SQLInstanceDetails {
    #---------------------------------------------------------[Parameters]------------------------------------------------------------
    param([Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string[]] $Name)

    #---------------------------------------------------------[Initializations]-------------------------------------------------------
    #region Initialization code
    Begin {
        $Cred = Get-StoredCredential -Target "Insight_DS"
        $Cred.Password.MakeReadOnly()
        $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username, $Cred.password)

        $script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

        $config = Get-Content -Path $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
        $SQLConnection = New-Object System.Data.SqlClient.SqlConnection
        $SQLConnection.ConnectionString = $config.settings.dbconnection

        $SQLConnection.Credential = $SQLCred
        $aResults = @()

    }
        #endregion Initialization code

    Process {
        ForEach ($Nm in $Name) {
            $SQLQuery ="declare @ID Int
            declare @RunCount Int
            set @ID =  (select Id from Instances
            where name like '$Nm%')
            set @RunCount = (Select max(runcount) from InstanceDetails where InstanceId = @ID)
            
            select I.Id, I.Name, D.Edition, D.Version, D.ServicePack, D.MachineType, D.AuthMode, D.TcpPort, D.BackupCompression, D.PowerPlan,
                D.MaxDOP, D.Xp_Cmdshell, D.ServerMemory_MB, D.MaxServerMemory_MB, D.MinServerMemory_MB, D.CPU_Count, D.InstallDate, D.LastStartDate, D.RunDate
                 from InstanceDetails D
                join Instances I
                on D.InstanceId = I.Id
                where RunCount = @RunCount
                and D.InstanceId = @Id"
            $SQLCmd = New-Object System.Data.SqlClient.SqlCommand
            $SQLCmd.CommandText = $SQLQuery
            $SQLCmd.Connection = $SQLConnection
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $SqlCmd
            $DataSet = New-Object System.Data.DataSet
            [void]$SqlAdapter.Fill($DataSet)

            if ($DataSet.Tables[0].Rows.Count -gt 0) {
    
                foreach ($row in $DataSet.Tables[0].Rows) {
                    $objectDetails = [PSCustomObject]@{
                        Id                 = "$($row.Id)"
                        Name               = "$($row.Name)"
                        Edition            = "$($row.Edition)"
                        Version            = "$($row.Version)"
                        ServicePack        = "$($row.ServicePack)"
                        MachineType        = "$($row.MachineType)"
                        AuthMode           = "$($row.AuthMode)"
                        TcpPort            = "$($row.TcpPort)"
                        BackupCompression  = "$($row.BackupCompression)"
                        PowerPlan          = "$($row.PowerPlan)"
                        MaxDOP             = "$($row.MaxDOP)"
                        Xp_Cmdshell        = "$($row.Xp_Cmdshell)"
                        ServerMemory_MB    = "$($row.ServerMemory_MB)"
                        MaxServerMemory_MB = "$($row.MaxServerMemory_MB)"
                        MinServerMemory_MB = "$($row.MinServerMemory_MB)"
                        CPU_Count          = "$($row.CPU_Count)"
                        InstallDate        = "$($row.InstallDate)"
                        LastStartDate      = "$($row.LastStartDate)"
                        RunDate            = "$($row.RunDate)"
                    }
                    $aResults += $objectDetails
                }
            }
            else {Write-Host "SQL Instance [$Name] not found"}
        }
    }
    
    End {
        [void]$SQLConnection.Close
        $aResults
    }
}

Export-ModuleMember -Function Get-SQLInstanceDetails
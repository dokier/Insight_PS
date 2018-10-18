<#
 .Synopsis
  Displays Insight batch process logs

 .Description
  Displays Insight batch process logs. This function let's you retrieve WRN, ERR
  or both log entries

 .Parameter Type
  Log Type, INF, WRN, ERR, ALL

 .Example
   # Display Error messages found in the last run of the process
   Get-InsightLogs -Type ERR
#>
function Get-JobLogs {
    #---------------------------------------------------------[Parameters]------------------------------------------------------------
    param([ValidateSet("INF", "WRN", "ERR", "ALL")][string] $Type = "ALL")

    #---------------------------------------------------------[Initializations]-------------------------------------------------------

    $LogType = @{"WRN" = "AND type = 'WRN'"; 
        "ERR"                = "AND type = 'ERR'";
        "ALL"                = "AND type IN ('WRN','ERR')"
    }

    $LogTypeFilter = $LogType[$Type]

    $script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

    $Cred = Get-StoredCredential -Target "Insight_DS"
    $Cred.Password.MakeReadOnly()
    $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username,$Cred.password)

    $SQLQuery = "SELECT * FROM joblogs WHERE RunCount IN (SELECT RunCount FROM jobs) $LogTypeFilter "
    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection

    $config = Get-Content -Path  $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
    $SQLConnection.ConnectionString = $config.settings.dbconnection
    $SQLConnection.Credential = $SQLCred
    $SQLCmd = New-Object System.Data.SqlClient.SqlCommand
    $SQLCmd.CommandText = $SQLQuery
    $SQLCmd.Connection = $SQLConnection
    $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd
    $DataSet = New-Object System.Data.DataSet
    [void]$SqlAdapter.Fill($DataSet)
    [void]$SQLConnection.Close

    $aResults = @()

    foreach ($row in $DataSet.Tables[0].Rows) {
        $objectDetails = [PSCustomObject]@{
            Id       = "$($row.Id)"
            RunDate  = "$($row.RunDate)"
            RunCount = "$($row.RunCount)"
            Type     = "$($row.Type)"
            Message  = "$($row.Message)"
        }
        $aResults += $objectDetails
    }
    $aResults
}

Export-ModuleMember -Function Get-JobLogs
<#
 .Synopsis
  Finds if SQL Instance exists on Instances Table

 .Description
  Finds if SQL Instance exists on Instances Table. This function queries Instances table on Insight database

 .Parameter Name
  Instance Name

 .Example
   # Serch for Instances with the name like 'SQLServer'
   Find-InsightInstance -Name 'SQLServer'
#>
function Find-SQLInstance {
    #---------------------------------------------------------[Parameters]------------------------------------------------------------
    param([Parameter(Mandatory = $true)][string] $Name)

    #---------------------------------------------------------[Initializations]-------------------------------------------------------

    $Cred = Get-StoredCredential -Target "Insight_DS"
    $Cred.Password.MakeReadOnly()
    $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username,$Cred.password)

    $script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

    $SQLQuery = "SELECT * FROM Instances WHERE Name like '%$Name%'"
    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection

    $config = Get-Content -Path $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
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
            Name  = "$($row.Name)"
            Environment = "$($row.Environment)"
            Active     = "$($row.Active)"
            Comments  = "$($row.Comments)"
        }
        $aResults += $objectDetails
    }
    $aResults
}

Export-ModuleMember -Function Find-SQLInstance
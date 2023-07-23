
Clear-Host

Import-Module -Name 'DotNetData' -Force

[int] $Script:DefaultCommandTimeout = 30

function Test-SqlServer {

   [Data.SqlClient.SqlConnection] $conn1 = New-SqlServerConnection -Server '{your-server-name-or-"localhost"}' -IntegratedSecurity -Verbose
   [Data.SqlClient.SqlConnection] $conn2 = New-SqlServerConnection -Server '{your-server-name-or-"localhost"}' -Port 1433 -User '{your-username}' -Verbose
   if ($conn1.State -eq 'Open' -and $conn2.State -eq 'Open') {
      Try {

         [String] $query1 = "select cast(ServerProperty(N'ServerName') as nvarchar(128)) [ServerName], db.[database_id], db.[name] [database_name], db.[compatibility_level], db.[state_desc], db.[recovery_model_desc] from [master].[sys].[databases] db where db.[database_id] > @dbid and db.[name] not in (@dbname) order by db.[name] asc;"
         [Collections.Generic.Dictionary[[String], [Data.SqlDbType]]] $paramTypeDict1 = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [Data.SqlDbType]]'
         $paramTypeDict1['@dbid'] = [Data.SqlDbType]::Int
         $paramTypeDict1['@dbname'] = [Data.SqlDbType]::NVarChar

         [String] $query2 = "select cast(ServerProperty(N'ServerName') as nvarchar(128)) [ServerName], db.[database_id], db.[name] [database_name], db.[compatibility_level], db.[state_desc], db.[recovery_model_desc] from [master].[sys].[databases] db where db.[database_id] > @dbid and db.[name] not in (@dbname) order by db.[name] asc;"
         [Collections.Generic.Dictionary[[String], [Data.SqlDbType]]] $paramTypeDict2 = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [Data.SqlDbType]]'
         $paramTypeDict2['@dbid'] = [Data.SqlDbType]::Int
         $paramTypeDict2['@dbname'] = [Data.SqlDbType]::NVarChar

         [Data.DataSet] $ds1 = New-DataSet
         [Data.DataSet] $ds2 = New-DataSet

         $conn1, $conn2 | % {
            [Data.Common.DbConnection] $conn = $_

            [Data.Common.DbDataAdapter] $da1 = New-DataAdapter -Connection $conn -Query $query1 -ParameterTypeDictionary $paramTypeDict1 -CommandTimeout $Script:DefaultCommandTimeout
            [Data.Common.DbDataAdapter] $da2 = New-DataAdapter -Connection $conn -Query $query2 -ParameterTypeDictionary $paramTypeDict2 -CommandTimeout $Script:DefaultCommandTimeout

            [Management.Automation.CallStackFrame] $csfTryCatch2 = (gcs)[0]; Try {

               $da1.SelectCommand.Parameters['@dbid'].Value = 2
               $da1.SelectCommand.Parameters['@dbname'].Value = 'tempdb'
               [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
               $rows1 | % {
                  [Data.DataRow] $row1 = $_
                  [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
                     DBMS               = 'SQL Server'
                     ServerName         = $row1.ServerName
                     DatabaseId         = $row1.database_id
                     DatabaseName       = $row1.database_name
                     CompatibilityLevel = $row1.compatibility_level
                     State              = $row1.state_desc
                     RecoveryModel      = $row1.recovery_model_desc
                  }
                  Write-Output -InputObject $obj
               } # % rows1

               $da2.SelectCommand.Parameters['@dbid'].Value = 2
               $da2.SelectCommand.Parameters['@dbname'].Value = 'tempdb'
               [Data.DataRow[]] $rows2 = Get-Rows -DataAdapter $da2 -DataSet $ds2
               $rows2 | % {
                  [Data.DataRow] $row2 = $_
                  [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
                     DBMS               = 'SQL Server'
                     ServerName         = $row2.ServerName
                     DatabaseId         = $row2.database_id
                     DatabaseName       = $row2.database_name
                     CompatibilityLevel = $row2.compatibility_level
                     State              = $row2.state_desc
                     RecoveryModel      = $row2.recovery_model_desc
                  }
                  Write-Output -InputObject $obj
               } # % rows2

            } # Try
            Catch {
               [Management.Automation.ErrorRecord] $er2 = $_
               Write-ErrorRecord -ErrorRecord $er2
            } # Catch
            Finally {
               $da1.Dispose()
               [Data.Common.DbDataAdapter] $da1 = $NULL
               $da2.Dispose()
               [Data.Common.DbDataAdapter] $da2 = $NULL
            } # Finally

         } # % $conns

      } # Try
      Catch {
         [Management.Automation.ErrorRecord] $er1 = $_
         Write-ErrorRecord -ErrorRecord $er1
      } # Catch
      Finally {
         if ($ds1 -ne $null) {
            $ds1.Dispose()
            [Data.DataSet] $ds1 = $NULL
         }
         if ($ds2 -ne $null) {
            $ds2.Dispose()
            [Data.DataSet] $ds2 = $NULL
         }
         if ($conn1.State -eq 'Open') {
            $conn1.Close()
         }
         if ($conn2.State -eq 'Open') {
            $conn2.Close()
         }
      } # Finally
   } # if ($conn1.State -eq 'Open' -and $conn2.State -eq 'Open')

} # function Test-SqlServer


[Object[]] $mssqlObjs = Test-SqlServer

if ($mssqlObjs.Count -le 0) {
   Write-Warning -Message "mssqlObjs.Count = $($mssqlObjs.Count)"
}
$mssqlObjs | Format-Table -AutoSize -GroupBy 'DBMS' -Property 'ServerName', 'DatabaseName', 'CompatibilityLevel', 'State', 'RecoveryModel'

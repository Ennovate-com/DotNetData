
Clear-Host

Import-Module -Name 'DotNetData' -Force

[int] $Script:DefaultCommandTimeout = 30

function Test-PostgreSQL {

   [Devart.Data.PostgreSql.PgSqlConnection] $conn1 = New-PostgreSqlConnection -Server '{your-server-name-or-"localhost"}' -UserName '{your-username}' -Verbose
   [Devart.Data.PostgreSql.PgSqlConnection] $conn2 = New-PostgreSqlConnection -Server '{your-server-name-or-"localhost"}' -Port 5432 -UserName '{your-username}' -Verbose
   if ($conn1.State -eq 'Open' -and $conn2.State -eq 'Open') {
      Try {
         if ($conn1.State -ne 'Open') {
            [String[]] $msgs = "Connection.State is not 'Open'", "Connection.State            = $($conn1.State)", "Connection.DataSource       = $($conn1.DataSource)", "Connection.Database         = $($conn1.Database)", "Connection.ConnectionString = $($conn1.ConnectionString)"
            Write-Error -Message ($msgs -join [Environment]::NewLine) -CategoryReason 'Connection not Open' -CategoryTargetName $conn1.DataSource -CategoryTargetType 'DataSource'
         }
         if ($conn2.State -ne 'Open') {
            [String[]] $msgs = "Connection.State is not 'Open'", "Connection.State            = $($conn2.State)", "Connection.DataSource       = $($conn2.DataSource)", "Connection.Database         = $($conn2.Database)", "Connection.ConnectionString = $($conn2.ConnectionString)"
            Write-Error -Message ($msgs -join [Environment]::NewLine) -CategoryReason 'Connection not Open' -CategoryTargetName $conn2.DataSource -CategoryTargetType 'DataSource'
         }

         [String] $query1 = "select 'XXX' XXX, @dbid dbid, @dbname dbname;"
         [Collections.Generic.Dictionary[[String], [Devart.Data.PostgreSql.PgSqlType]]] $paramTypeDict1 = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [Devart.Data.PostgreSql.PgSqlType]]'
         $paramTypeDict1['@dbid'] = [Devart.Data.PostgreSql.PgSqlType]::Int
         $paramTypeDict1['@dbname'] = [Devart.Data.PostgreSql.PgSqlType]::VarChar

         [String] $query2 = "select 'YYY' XXX, @dbid dbid, @dbname dbname;"
         [Collections.Generic.Dictionary[[String], [Devart.Data.PostgreSql.PgSqlType]]] $paramTypeDict2 = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [Devart.Data.PostgreSql.PgSqlType]]'
         $paramTypeDict2['@dbid'] = [Devart.Data.PostgreSql.PgSqlType]::Int
         $paramTypeDict2['@dbname'] = [Devart.Data.PostgreSql.PgSqlType]::VarChar

         [Data.DataSet] $ds1 = New-DataSet
         [Data.DataSet] $ds2 = New-DataSet

         $conn1, $conn2 | % {
            [Data.Common.DbConnection] $conn = $_

            [Data.Common.DbDataAdapter] $da1 = New-DataAdapter -Connection $conn -Query $query1 -ParameterTypeDictionary $paramTypeDict1 -CommandTimeout $Script:DefaultCommandTimeout
            [Data.Common.DbDataAdapter] $da2 = New-DataAdapter -Connection $conn -Query $query2 -ParameterTypeDictionary $paramTypeDict2 -CommandTimeout $Script:DefaultCommandTimeout

            [Management.Automation.CallStackFrame] $csfTryCatch2 = (gcs)[0]; Try {

               $da1.SelectCommand.Parameters['@dbid'].Value = 1
               $da1.SelectCommand.Parameters['@dbname'].Value = 'aaa'
               [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
               $rows1 | % {
                  [Data.DataRow] $row1 = $_
                  [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
                     DBMS   = 'PostgreSQL'
                     XXX    = $row1.XXX
                     DbId   = $row1.dbid
                     DbName = $row1.dbname
                  }
                  Write-Output -InputObject $obj
               } # % rows1

               $da2.SelectCommand.Parameters['@dbid'].Value = 2
               $da2.SelectCommand.Parameters['@dbname'].Value = 'bbb'
               [Data.DataRow[]] $rows2 = Get-Rows -DataAdapter $da2 -DataSet $ds2
               $rows2 | % {
                  [Data.DataRow] $row2 = $_
                  [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
                     DBMS   = 'PostgreSQL'
                     XXX    = $row2.XXX
                     DbId   = $row2.dbid
                     DbName = $row2.dbname
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

} # function Test-PostgreSQL


[Object[]] $pgsqlObjs = Test-PostgreSQL

if ($pgsqlObjs.Count -le 0) {
   Write-Warning -Message "pgsqlObjs.Count = $($pgsqlObjs.Count)"
}
$pgsqlObjs | Format-Table -AutoSize -GroupBy 'DBMS' -Property 'xxx', 'dbid', 'dbname'

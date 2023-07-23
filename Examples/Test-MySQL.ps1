
Clear-Host

Import-Module -Name 'DotNetData' -Force

[int] $Script:DefaultCommandTimeout = 30

function Test-MySQL {

   [MySql.Data.MySqlClient.MySqlConnection] $conn1 = New-MySqlConnection -Server '{your-server-name-or-"localhost"}' -UserName '{your-username}' -Verbose
   [MySql.Data.MySqlClient.MySqlConnection] $conn2 = New-MySqlConnection -Server '{your-server-name-or-"localhost"}' -Port 3306 -UserName '{your-username}' -Verbose
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

         [String] $query1 = "show databases like @pattern;"
         [Collections.Generic.Dictionary[[String], [MySql.Data.MySqlClient.MySqlDbType]]] $paramTypeDict1 = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [MySql.Data.MySqlClient.MySqlDbType]]'
         $paramTypeDict1['@pattern'] = [MySql.Data.MySqlClient.MySqlDbType]::VarChar

         [String] $query2 = "select s.CATALOG_NAME, s.SCHEMA_NAME, s.DEFAULT_CHARACTER_SET_NAME, s.DEFAULT_COLLATION_NAME, s.SQL_PATH from INFORMATION_SCHEMA.SCHEMATA s order by s.CATALOG_NAME asc, s.SCHEMA_NAME asc;"
         [Collections.Generic.Dictionary[[String], [MySql.Data.MySqlClient.MySqlDbType]]] $paramTypeDict2 = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [MySql.Data.MySqlClient.MySqlDbType]]'
         $paramTypeDict2['@datetime'] = [MySql.Data.MySqlClient.MySqlDbType].GetMember('DateTime').GetRawConstantValue()
<# Misleading error if enum for type does not exist or is "DateTime" or "Datetime":
         $paramTypeDict2['@datetime'] = [MySql.Data.MySqlClient.MySqlDbType]::Invalid
         $paramTypeDict2['@datetime'] = [MySql.Data.MySqlClient.MySqlDbType]::DateTime
         $paramTypeDict2['@datetime'] = [MySql.Data.MySqlClient.MySqlDbType]::Datetime
   The field or property: "Datetime" for type: "MySql.Data.MySqlClient.MySqlDbType" differs only in letter casing from the field or property: "DateTime".
   The type must be Common Language Specification (CLS) compliant.
         $paramTypeDict2['@datetime'] = [MySql.Data.MySqlClient.MySqlDbType].GetMember('DateTime').GetRawConstantValue()
#>

         [Data.DataSet] $ds1 = New-DataSet
         [Data.DataSet] $ds2 = New-DataSet

         $conn1, $conn2 | % {
            [Data.Common.DbConnection] $conn = $_

            [Data.Common.DbDataAdapter] $da1 = New-DataAdapter -Connection $conn -Query $query1 -ParameterTypeDictionary $paramTypeDict1 -CommandTimeout $Script:DefaultCommandTimeout
            [Data.Common.DbDataAdapter] $da2 = New-DataAdapter -Connection $conn -Query $query2 -ParameterTypeDictionary $paramTypeDict2 -CommandTimeout $Script:DefaultCommandTimeout

            [Management.Automation.CallStackFrame] $csfTryCatch2 = (gcs)[0]; Try {

               $da1.SelectCommand.Parameters['@pattern'].Value = '%s%'
               [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
               $rows1 | % {
                  [Data.DataRow] $row1 = $_
                  [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
                     DBMS                    = 'MySQL'
                     CatalogName             = ''
                     SchemaName              = $row1.'Database (%s%)'
                     DefaultCharacterSetName = ''
                     DefaultCollationName    = ''
                     SqlPath                 = ''
                  }
                  Write-Output -InputObject $obj
               } # % rows1

               $da2.SelectCommand.Parameters['@datetime'].Value = '2023-01-01'
               [Data.DataRow[]] $rows2 = Get-Rows -DataAdapter $da2 -DataSet $ds2
               $rows2 | % {
                  [Data.DataRow] $row2 = $_
                  [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
                     DBMS                    = 'MySQL'
                     CatalogName             = $row2.CATALOG_NAME
                     SchemaName              = $row2.SCHEMA_NAME
                     DefaultCharacterSetName = $row2.DEFAULT_CHARACTER_SET_NAME
                     DefaultCollationName    = $row2.DEFAULT_COLLATION_NAME
                     SqlPath                 = $row2.SQL_PATH
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

} # function Test-MySQL


[Object[]] $mysqlObjs = Test-MySQL

if ($mysqlObjs.Count -le 0) {
   Write-Warning -Message "mysqlObjs.Count = $($mysqlObjs.Count)"
}
$mysqlObjs | Format-Table -AutoSize -GroupBy 'DBMS' -Property 'CatalogName', 'SchemaName', 'DefaultCharacterSetName', 'DefaultCollationName', 'SqlPath'

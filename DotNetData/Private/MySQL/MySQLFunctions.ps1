
function Initialize-MySqlConnectionStringBuilder {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [MySql.Data.MySqlClient.MySqlConnectionStringBuilder[]] $ConnectionStringBuilder
   )

   Begin {
   }

   Process {

      $ConnectionStringBuilder | % {
         [MySql.Data.MySqlClient.MySqlConnectionStringBuilder] $csb = $_

         $csb.Clear()

         $csb['AllowBatch'] = $true
#         $csb['AllowLoadLocalInfile'] = $true
#         $csb['AllowPublicKeyRetrieval'] = $false
         $csb['AllowUserVariables'] = $true # default: $false
         $csb['AllowZeroDateTime'] = $true # default: $false
         $csb['AutoEnlist'] = $true
#         $csb['BlobAsUTF8ExcludePattern'] = 
#         $csb['BlobAsUTF8IncludePattern'] = 
#         $csb['BrowsableConnectionString'] = $true
         $csb['CacheServerProperties'] = $false
#         $csb['CertificateFile'] = 
#         $csb['CertificatePassword'] = 
         $csb['CertificateStoreLocation'] = [MySql.Data.MySqlClient.MySqlCertificateStoreLocation]::None
#         $csb['CertificateThumbprint'] = 
         $csb['CharacterSet'] = 'utf8'
         $csb['CheckParameters'] = $true
#         $csb['CommandInterceptors'] = 
         $csb['ConnectionLifeTime'] = 0
#         $csb['ConnectionProtocol'] = [MySql.Data.MySqlClient.MySqlConnectionProtocol]::Socket
         $csb['ConnectionReset'] = $false
#         $csb['ConnectionString'] = 
         $csb['ConnectionTimeout'] = 30 # default: 15
         $csb['ConvertZeroDateTime'] = $false
#         $csb['Count'] = 0
#         $csb['Database'] = 
         $csb['DefaultCommandTimeout'] = $Script:DefaultCommandTimeout
         $csb['DefaultTableCacheAge'] = 60
#         $csb['DnsSrv'] = 
#         $csb['ExceptionInterceptors'] = 
         $csb['FunctionsReturnString'] = $false
<# deprecated in Connector/NET 8.0.23 release and removed in Connector/NET 8.0.24 release.
         https://docs.oracle.com/cd/E17952_01/connector-net-relnotes-en/news-8-0-24.html
         $csb['IgnorePrepare'] = $false # default: $true
#>
         $csb['IncludeSecurityAsserts'] = $true # default: $false; must be $true if the MySQL Connector library is installed in the GAC
#         $csb['IntegratedSecurity'] = $false
         $csb['InteractiveSession'] = $true
#         $csb['IsFixedSize'] = $false
#         $csb['IsReadOnly'] = $false
#         $csb['Item'] =
         $csb['Keepalive'] = 0
#         $csb['Keys'] = 
         $csb['Logging'] = $true
         $csb['MaximumPoolSize'] = 100
         $csb['MinimumPoolSize'] = 0
         $csb['OldGuids'] = $false
#         $csb['Password'] = 
         $csb['PersistSecurityInfo'] = $false
#         $csb['PipeName'] = 'MYSQL'
         $csb['Pooling'] = $true
#         $csb['Port'] = 3306
         $csb['ProcedureCacheSize'] = 25
         $csb['Replication'] = $false
         $csb['RespectBinaryFlags'] = $true
#         $csb['Server'] = 
         $csb['SharedMemoryName'] = 'MYSQL'
         $csb['SqlServerMode'] = $false
#         $csb['SshHostName'] = 
#         $csb['SshKeyFile'] = 
#         $csb['SshPassphrase'] = 
#         $csb['SshPassword'] = 
#         $csb['SshPort'] = 
#         $csb['SshUserName'] = 
#         $csb['SslCa'] = 
#         $csb['SslCert'] = 
#         $csb['SslKey'] = 
         if ([enum]::GetNames([MySql.Data.MySqlClient.MySqlSslMode]) -contains 'Preferred') {
            $csb['SslMode'] = [MySql.Data.MySqlClient.MySqlSslMode]::Preferred
         }
         elseif ([enum]::GetNames([MySql.Data.MySqlClient.MySqlSslMode]) -contains 'Prefered') {
            $csb['SslMode'] = [MySql.Data.MySqlClient.MySqlSslMode]::Prefered
         }
         else {
            $csb['SslMode'] = [MySql.Data.MySqlClient.MySqlSslMode]::None
         }
         $csb['TableCaching'] = $false
#         $csb['TlsVersion'] = 
         $csb['TreatBlobsAsUTF8'] = $false
         $csb['TreatTinyAsBoolean'] = $true
         $csb['UseAffectedRows'] = $true # default: $false
         $csb['UseCompression'] = $true # default: $false
         $csb['UseDefaultCommandTimeoutForEF'] = $true # default: $false
         $csb['UsePerformanceMonitor'] = $true # default: $false
#         $csb['UserID'] = 
         $csb['UseUsageAdvisor'] = $true # default: $false
#         $csb['Values'] = 

      } # % $ConnectionStringBuilder

   } # Process

   End {
   }

}

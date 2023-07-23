
#[int] $Script:DefaultCommandTimeout = 300 # default is 30

function Initialize-SqlServerConnectionStringBuilder {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.SqlClient.SqlConnectionStringBuilder[]] $ConnectionStringBuilder
   )

   Begin {
   }

   Process {

      $ConnectionStringBuilder | % {
         [Data.SqlClient.SqlConnectionStringBuilder] $csb = $_

         $csb.Clear()

#         $csb['ApplicationName'] = '.Net SqlClient Data Provider'
         $csb['Asynchronous Processing'] = $true # default: $false
#         $csb['AttachDBFilename'] = 
#         $csb['Authentication'] = [Data.SqlClient.SqlAuthenticationMethod]::NotSpecified # for Azure SQL Database
#         $csb['BrowsableConnectionString'] = $true
#         $csb['Column Encryption Setting'] = [Data.SqlClient.SqlConnectionColumnEncryptionSetting]::Disabled # instance must support column encryption
#         $csb['ConnectionString'] = 
         $csb['Connect Timeout'] = 30 # default: 15
         $csb['Context Connection'] = $false
#         $csb['Count'] = 0
         $csb['Current Language'] = 'us_english'
#         $csb['DataSource'] = 
#         $csb['Enclave Attestation Url'] = '???'
         $csb['Encrypt'] = $false
         $csb['Enlist'] = $true
#         $csb['Failover Partner'] = '???'
#         $csb['InitialCatalog'] = 
#         $csb['IntegratedSecurity'] = $false
#         $csb['IsFixedSize'] = $true
#         $csb['IsReadOnly'] = $false
#         $csb['Item[...]
#         $csb['Keys =
         $csb['Load Balance Timeout'] = 0
#         $csb['MaxPoolSize'] = 100
#         $csb['MinPoolSize'] = 0
         $csb['MultipleActiveResultSets'] = $true # default: $false
#         $csb['NetworkLibrary'] = 
         $csb['Packet Size'] = 8000
#         $csb['Password'] = 
         $csb['PersistSecurityInfo'] = $false
#         $csb['PoolBlockingPeriod'] = [Data.SqlClient.PoolBlockingPeriod]::Auto
         $csb['Pooling'] = $true
         $csb['Replication'] = $false
         $csb['Transaction Binding'] = 'Implicit Unbind'
#         $csb['TransparentNetworkIPResolution'] = $true
         $csb['TrustServerCertificate'] = $true # default: $false
         $csb['Type System Version'] = 'Latest'
#         $csb['UserID'] = 
         $csb['User Instance'] = $false
#         $csb['Values =
#         $csb['WorkstationID'] = 
         if ($PSVersionTable.PSVersion.Major -ge 3) {
            $csb['ApplicationIntent'] = [Data.SqlClient.ApplicationIntent]::ReadWrite
            $csb['ConnectRetryCount'] = 1
            $csb['ConnectRetryInterval'] = 5 # default: 10
            $csb['MultiSubnetFailover'] = $true
         }

      } # % $ConnectionStringBuilder

   } # Process

   End {
   }

}

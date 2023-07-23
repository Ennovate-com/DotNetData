
function Initialize-PostgreSqlConnectionStringBuilder {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Devart.Data.PostgreSql.PgSqlConnectionStringBuilder[]] $ConnectionStringBuilder
   )

   Begin {
   }

   Process {

      $ConnectionStringBuilder | % {
         [Devart.Data.PostgreSql.PgSqlConnectionStringBuilder] $csb = $_

         $csb.Clear()

#         $csb['AllowDateTimeOffset'] = 
#         $csb['ApplicationName'] = 
#         $csb['Charset'] = 
#         $csb['ConnectionLifetime'] = 
#         $csb['ConnectionTimeout'] = 
#         $csb['Database'] = 
#         $csb['DefaultCommandTimeout'] = 
#         $csb['DefaultFetchAll'] = 
#         $csb['Enlist'] = 
#         $csb['ForceIPv4'] = 
#         $csb['Host'] = 
#         $csb['IgnoreUnnamedParameters'] = 
#         $csb['InitializationCommand'] = 
#         $csb['IntegratedSecurity'] = $false 
#         $csb['IsFixedSize'] = 
#         $csb['IsReadOnly'] = 
#         $csb['JoinStatementNotices'] = 
#         $csb['KeepAlive'] = 
#         $csb['KeepConnected'] = 
#         $csb['MaxPoolSize'] = 
#         $csb['MinPoolSize'] = 
#         $csb['Password'] = 
#         $csb['PersistSecurityInfo'] = 
#         $csb['Pooling'] = 
#         $csb['Port'] = 
#         $csb['Protocol'] =  
#         $csb['ProxyHost'] =  
#         $csb['ProxyPassword'] =  
#         $csb['ProxyPort'] = 
#         $csb['ProxyUser'] = 
#         $csb['RunOnceCommand'] = 
#         $csb['Schema'] = 
#         $csb['SshAuthenticationType'] = 
#         $csb['SshCipherList'] = 
#         $csb['SshHost'] =  
#         $csb['SshHostKey'] = 
#         $csb['SshPassphrase'] = 
#         $csb['SshPassword'] = 
#         $csb['SshPort'] =   
#         $csb['SshPrivateKey'] =   
#         $csb['SshStrictHostKeyChecking'] =  
#         $csb['SshUser'] = 
#         $csb['SslCACert'] = 
#         $csb['SslCert'] = 
#         $csb['SslCipherList'] = 
#         $csb['SslKey'] =  
#         $csb['SslMode'] =  
#         $csb['SslTlsProtocol'] = 
#         $csb['TargetSession'] =  
#         $csb['TransactionErrorBehavior'] = 
#         $csb['TransactionScopeLocal'] = 
#         $csb['Unicode'] = 
#         $csb['UnpreparedExecute'] =  
#         $csb['UserId'] =   
#         $csb['ValidateConnection'] = 

      } # % $ConnectionStringBuilder

   } # Process

   End {
   }

}

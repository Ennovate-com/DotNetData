
[Boolean] $Script:firstPostgreSQLConn = $true

$Script:pgcsb = $null

function New-PostgreSqlConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $Server,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateRange(-1,65535)]
      [int] $Port = -1,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $DatabaseName = 'postgres',
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

   # Load PostgreSQL.Data.dll

      if ($Script:firstPostgreSQLConn) {
         $firstPostgreSQLConn = $false

         [Object] $pgsqlConfig = Get-DotNetDataConfiguration -DBMS 'PostgreSQL'

      # Load the DLL for PostgreSQL Connector for .NET

         Import-Dll -DllPath $pgsqlConfig.DllPath

      } # if ($Script:firstPostgreSQLConn)

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:pgcsb -eq $NULL) {
         [Devart.Data.PostgreSql.PgSqlConnectionStringBuilder] $Script:pgcsb = New-Object -TypeName 'Devart.Data.PostgreSql.PgSqlConnectionStringBuilder'
      }

   } # Begin

   Process {

      Initialize-PostgreSqlConnectionStringBuilder -ConnectionStringBuilder $Script:pgcsb

      $Script:pgcsb['Server'] = $Server
      if ($Port -ge 0) {
         $Script:pgcsb['Port'] = $Port
      }
      $Script:pgcsb['Database'] = $DatabaseName
      $Script:pgcsb['UserId'] = $UserName
      [Management.Automation.PSCredential] $Credential = Get-CredentialForUserName -UserName $UserName -CallStackFrame $CallStackFrame
      if ($Credential -ne $null) {
         $Script:pgcsb['UserId'] = $Credential.UserName
         $Script:pgcsb['Password'] = $Credential.GetNetworkCredential().Password
      }
      [String[]] $connstrs = , $Script:pgcsb.ToString()

   # Connect to PostgreSQL instances

      $connstrs | % {
         $connstr = $_

         [Devart.Data.PostgreSql.PgSqlConnection] $conn = New-Object -TypeName 'Devart.Data.PostgreSql.PgSqlConnection' ($connstr)

         [String] $server = $connstr.Substring($connstr.IndexOf('Host=') + 5, $connstr.IndexOf(';', $connstr.IndexOf('Host=')) - $connstr.IndexOf('Host=') - 5)
         Try {
            $conn.Open()
            if ($conn.State -ne 'Open') {
               [String[]] $msgs = "$($MyInvocation.MyCommand.Name): conn.Open() with Data Source=${server}", "$($MyInvocation.MyCommand.Name): Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
               Write-Error -Message ($msgs -join [Environment]::NewLine) -CategoryReason 'MySqlConnection.Open failed' -CategoryTargetName $server -CategoryTargetType 'Server'
            }
         }
         Catch {
            [Management.Automation.ErrorRecord] $er = $_
            Write-Error -ErrorRecord $er -CategoryReason 'MySqlConnection.Open threw exception' -CategoryTargetName $server -CategoryTargetType 'Server'
         }

         Write-Output -InputObject $conn

      } # % $connstrs

   } # Process

   End {
   } # End

} # function New-PostgreSqlConnection

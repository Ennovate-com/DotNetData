
[Data.SqlClient.SqlConnectionStringBuilder] $Script:sscsb = $NULL

#[int] $Script:DefaultCommandTimeout = 300 # default is 30

function New-SqlServerConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $Server,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateRange(-1,65535)]
      [Int] $Port = -1,
      [Parameter(ParameterSetName = 'IntegratedSecurity', Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $IntegratedSecurity,
      [Parameter(ParameterSetName = 'UserName', Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $DatabaseName = [NullString]::Value,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [AllowEmptyString()]
      [String] $ApplicationName = [NullString]::Value,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [Int] $ConnectTimeout = -1,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Nullable[Boolean]] $MultiSubnetFailover = $null,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      [Management.ManagementObject] $cs = Get-WmiObject 'Win32_ComputerSystem'
      $computerName = "$($cs.Name).$($cs.Domain)"

      if ([String]::IsNullOrEmpty($ApplicationName)) {
         $ApplicationName = $CallStackFrame.ScriptName
      }

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:sscsb -eq $NULL) {
         [Data.SqlClient.SqlConnectionStringBuilder] $Script:sscsb = New-Object -TypeName 'Data.SqlClient.SqlConnectionStringBuilder'

      }

   }

   Process {

      Initialize-SqlServerConnectionStringBuilder -ConnectionStringBuilder $Script:sscsb
      if ($Port -lt 0) {
         $Script:sscsb['Data Source'] = $Server
      }
      else {
         $Script:sscsb['Data Source'] = "${Server},${Port}"
      }
      if (-not [String]::IsNullOrEmpty($DatabaseName)) {
         $Script:sscsb['Initial Catalog'] = $DatabaseName
      }
      switch -Exact ($PSCmdlet.ParameterSetName) {
         'IntegratedSecurity' {
            $Script:sscsb['Integrated Security'] = $true
#            $Script:sscsb.Remove('User ID')
#            $Script:sscsb.Remove('Password')
         }
         'UserName' {
            $Script:sscsb['Integrated Security'] = $false
            $Script:sscsb['User ID'] = $UserName
            [Management.Automation.PSCredential] $Credential = Get-CredentialForUserName -UserName $UserName -CallStackFrame $CallStackFrame
            if ($Credential -ne $null) {
               $Script:sscsb['User ID'] = $Credential.UserName
               $Script:sscsb['Password'] = $Credential.GetNetworkCredential().Password
            }
         }
         default {
            Write-Error -Message "ParameterSetName '$($PSCmdlet.ParameterSetName)' not recognized" -CategoryReason 'Coding error in module!' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'ModuleFile'
         }
      }

      $Script:sscsb['Application Name'] = $ApplicationName
      if ($ConnectTimeout -ne -1) {
         $Script:sscsb['Connect Timeout'] = $ConnectTimeout
      }
#      $Script:sscsb['Workstation ID'] = [System.Net.DNS]::GetHostByName($Null).HostName
      $Script:sscsb['Workstation ID'] = $computerName

      if ($PSVersionTable.PSVersion.Major -ge 3 -and $MultiSubnetFailover -ne $null) {
         $Script:sscsb['MultiSubnetFailover'] = $MultiSubnetFailover
      }

      [String[]] $connstrs = , $Script:sscsb.ToString()

   # Connect to SQL Server instances

      $connstrs | % {
         $connstr = $_

         [Data.SqlClient.SqlConnection] $conn = New-Object -TypeName 'Data.SqlClient.SqlConnection' ($connstr)

         [String] $server = $connstr.Substring($connstr.IndexOf('Data Source=') + 12, $connstr.IndexOf(';', $connstr.IndexOf('Data Source=')) - $connstr.IndexOf('Data Source=') - 12)
         Try {
            $conn.Open()
            if ($conn.State -ne 'Open') {
               [String[]] $msgs = "$($MyInvocation.MyCommand.Name): conn.Open() with Data Source=${server}", "Connection.Type             = $($conn.GetType().FullName)", "Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
               Write-Error -Message ($msgs -join [Environment]::NewLine) -CategoryReason 'SqlConnection.Open failed' -CategoryTargetName $server -CategoryTargetType 'Server'
            }
         }
         Catch {
            [Management.Automation.ErrorRecord] $er = $_
            Write-Error -ErrorRecord $er -CategoryReason 'SqlConnection.Open threw exception' -CategoryTargetName $server -CategoryTargetType 'Server'
         }

         Write-Output -InputObject $conn

      } # % $connstrs

   } # Process

   End {
   }

}


[Data.SqlClient.SqlConnectionStringBuilder] $Script:sscsb = $NULL

#[int] $Script:DefaultCommandTimeout = 300 # default is 30

function New-SqlServerConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $Server,
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

      [Collections.Generic.Queue[string]] $queue = New-Object -TypeName 'Collections.Generic.Queue[string]'
      [Collections.Generic.List[string]] $alreadyBeingTried = New-Object -TypeName 'Collections.Generic.List[string]'

   }

   Process {

   # When $Server is from "-Server" parameter, each item in [String[]] $Server list is processed separately
   # for each item, return a single connection for just one name in $queue (vs. adding all $Server items to $queue at once)
      $Server | % {
         [String] $aServer = $_

         $queue.Clear()
         $alreadyBeingTried.Clear()
         $queue.Enqueue($aServer)
         [void] $alreadyBeingTried.Add($aServer)

         while ($queue.Count -gt 0) {
            [String] $tryServer = $queue.Dequeue()
            Write-Verbose -Message "tryServer: ${tryServer}"

            Initialize-SqlServerConnectionStringBuilder -ConnectionStringBuilder $Script:sscsb
            if ($Port -lt 0) {
               $Script:sscsb['Data Source'] = $tryServer
            }
            else {
               $Script:sscsb['Data Source'] = "${tryServer},${Port}"
            }
            if (-not [String]::IsNullOrEmpty($DatabaseName)) {
               $Script:sscsb['Initial Catalog'] = $DatabaseName
            }
            switch -Exact ($PSCmdlet.ParameterSetName) {
               'IntegratedSecurity' {
                  $Script:sscsb['Integrated Security'] = $true
#                  $Script:sscsb.Remove('User ID')
#                  $Script:sscsb.Remove('Password')
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
#            $Script:sscsb['Workstation ID'] = [System.Net.DNS]::GetHostByName($Null).HostName
            $Script:sscsb['Workstation ID'] = $computerName

            if ($PSVersionTable.PSVersion.Major -ge 3 -and $MultiSubnetFailover -ne $null) {
               $Script:sscsb['MultiSubnetFailover'] = $MultiSubnetFailover
            }

            [String[]] $connstr = $Script:sscsb.ToString()

         # Connect to SQL Server instance

            [Data.SqlClient.SqlConnection] $conn = New-Object -TypeName 'Data.SqlClient.SqlConnection' ($connstr)

#            [String] $xServer = $connstr.Substring($connstr.IndexOf('Data Source=') + 12, $connstr.IndexOf(';', $connstr.IndexOf('Data Source=')) - $connstr.IndexOf('Data Source=') - 12)
            Try {
               $conn.Open()
               if ($conn.State -ne 'Open') {
                  [String[]] $msgs = "$($MyInvocation.MyCommand.Name): conn.Open() with Data Source=${server}", "Connection.Type             = $($conn.GetType().FullName)", "Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
                  Write-Error -Message ($msgs -join [Environment]::NewLine) -CategoryReason 'SqlConnection.Open failed' -CategoryTargetName $tryServer -CategoryTargetType 'Server'
               }
               elseif ($tryServer -ne $aServer) {
                  Write-Warning -Message "Connection with DNS Name ${tryServer} was successful but ${aServer} was not$([Environment]::NewLine)         SPN for ${aServer} may be missing$([Environment]::NewLine)         Check with: setspn -Q `"MSSQLSvc/${aServer}`"$([Environment]::NewLine)         Compare to: setspn -Q `"MSSQLSvc/${tryServer}`""
               }
               Write-Output -InputObject $conn
               return
            }
            Catch {
               [Management.Automation.ErrorRecord] $er = $_
               Write-Error -ErrorRecord $er -CategoryReason 'SqlConnection.Open threw exception' -CategoryTargetName $tryServer -CategoryTargetType 'Server'
               if ($er.FullyQualifiedErrorId -eq 'SqlException') {
                  Write-Warning -Message "HResult $('0x{0:x8}' -f $er.Exception.HResult) $($er.Exception.Message)"
                  if ($er.Exception.HResult -eq 0x80131501) {
                     # Login failed. The login is from an untrusted domain and cannot be used with Windows authentication.

                  # Check for DNS CNAME record with this $tryServer as an alias for a canonical name
                     [Object[]] $dnsRecords = Resolve-DnsName -Name $tryServer -Type 'CNAME' -Verbose:$false
                        # Object[ Microsoft.DnsClient.Commands.DnsRecord_PTR | Microsoft.DnsClient.Commands.DnsRecord_A ]
                     Write-Verbose -Message "Resolve-DnsName -Name '${tryServer}' -Type 'CNAME' - $($dnsRecords.Count) DNS Record(s)"
                     $dnsRecords | % {
                        $dnsRecord = $_
                        if ($dnsRecord.Section -eq 'Answer' -and $dnsRecord.Type -eq 'CNAME') {
                           [String] $anotherToTry = $dnsRecord.NameHost
                           if ($alreadyBeingTried -notcontains $anotherToTry) {
                              Write-Warning -Message "$($dnsRecord.Name) is an alias in a DNS CNAME record pointing to canonical host name $($dnsRecord.NameHost)"
                              $queue.Enqueue($anotherToTry)
                              [void] $alreadyBeingTried.Add($anotherToTry)
                           }
                        }
                     } # % $dnsRecords

                  # Search for any DNS alias CNAME records with this $tryServer as the canonical name
                     # TO DO

                  # Check for alternate host name(s)
                     [Object[]] $dnsRecords = Resolve-DnsName -Name $tryServer -Type 'A_AAAA' -Verbose:$false
                     Write-Verbose -Message "Resolve-DnsName -Name '${tryServer}' -Type 'A_AAAA' - $($dnsRecords.Count) DNS Record(s)"
                     $dnsRecords | % {
                        $dnsRecord = $_
                        if ($dnsRecord.Section -eq 'Answer') {
                           if ('A', 'AAAA' -contains $dnsRecord.Type) {
                           # Look up HostName in DNS
                           # If different, it may have a DNS alias CNAME record with this $tryServer as the canonical name
                              Write-Verbose -Message "dnsRecord.Name: $($dnsRecord.Name) GetHostEntry('$($dnsRecord.IPAddress)')"
                              Try {
                                 [Net.IPHostEntry] $ipHostEntry = [System.Net.Dns]::GetHostEntry($dnsRecord.IPAddress)
                              }
                              Catch {
                                 [Management.Automation.ErrorRecord] $er = $_
                                 Write-Verbose -Message "[System.Net.Dns]::GetHostEntry('$($dnsRecord.IPAddress)') ${er}"
                                 [Net.IPHostEntry] $ipHostEntry = $null
                              }
                              if ($ipHostEntry -ne $null) {
                                 [String] $anotherToTry = $ipHostEntry.HostName
                                 if ($alreadyBeingTried -notcontains $anotherToTry) {
                                 # Check to see if it is a CNAME
                                    Write-Verbose -Message "Resolve-DnsName -Name '${anotherToTry}' -Type 'CNAME'"
                                    [Object[]] $dnsRecords2 = Resolve-DnsName -Name $anotherToTry -Type 'CNAME' -Verbose:$false
                                    $dnsRecords2 | % {
                                       $dnsRecord2 = $_
                                       if ($dnsRecord2.Section -eq 'Answer' -and $dnsRecord2.Type -eq 'CNAME') {
                                          [String] $anotherToTry2 = $dnsRecord2.Name
                                          if ($alreadyBeingTried -notcontains $anotherToTry2) {
                                             Write-Warning -Message "$($dnsRecord2.NameHost) is canonical host name in DNS CNAME record for alias $($dnsRecord2.Name)"
                                             $queue.Enqueue($anotherToTry2)
                                             [void] $alreadyBeingTried.Add($anotherToTry2)
                                          }
                                       }
                                    } # % $dnsRecords2
                                 # Else add it
                                    [String] $anotherToTry = $ipHostEntry.HostName
                                    if ($alreadyBeingTried -notcontains $anotherToTry) {
                                       Write-Warning -Message "Also trying HostName ${anotherToTry} from HostEntry"
                                       $queue.Enqueue($anotherToTry)
                                       [void] $alreadyBeingTried.Add($anotherToTry)
                                    }
                                 }
                              # Check all addresses in AddressList from HostEntry
                                 $ipHostEntry.AddressList | % {
                                    $ipAddr = $_
                                    if ($ipAddr -eq '::1') {
                                       return
                                    }
                                    Write-Verbose -Message "Checking IP Address ${ipAddr}"
                                    if ($ipAddr -ne $dnsRecord.IPAddress) {
                                    }
                                 }
                                 if ($tryServer -eq 'int.da1sans01pav.stsky.biz') {
                                    [String] $anotherToTry = 'da1sans01pav.stsky.biz'
                                    if ($alreadyBeingTried -notcontains $anotherToTry) {
                                       Write-Warning -Message "${tryServer} is a canonical name for an alias with a DNS CNAME record ${anotherToTry}"
                                       $queue.Enqueue($anotherToTry)
                                       [void] $alreadyBeingTried.Add($anotherToTry)
                                    }
                                 }
                              } # if ($ipHostEntry -ne $null)
                           }
                           else {
                              Write-Warning -Message "Unexpected 'Answer' Type: $($dnsRecord.Type)"
                           }
                        } # if ($dnsRecord.Section -eq 'Answer')
                     } # % $dnsRecords

                  } # if ($er.Exception.HResult -eq 0x80131501)
               } # if ($er.FullyQualifiedErrorId -eq 'SqlException')
            } # Catch

         } # while ($queue.Count -gt 0)

      } # % $Server

   } # Process

   End {
   }

}

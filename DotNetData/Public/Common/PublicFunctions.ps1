<# DataFunctions.ps1
#>

function Write-ErrorRecord {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Management.Automation.ErrorRecord] $ErrorRecord
   )

<#

# ErrorRecord

   Write-Warning -Message "Type:                  $($ErrorRecord.GetType().FullName)"
   Write-Warning -Message "ToString():            $($ErrorRecord.ToString())"
   if ($ErrorRecord.ErrorDetails -ne $null) {
      Write-Warning -Message "ErrorDetails:          $($ErrorRecord.ErrorDetails)"
   }
   Write-Warning -Message "Exception:             $($ErrorRecord.Exception)"
   Write-Warning -Message "FullyQualifiedErrorId: $($ErrorRecord.FullyQualifiedErrorId)"
   if ($ErrorRecord.PipelineIterationInfo -ne $null) {
      Write-Warning -Message "PipelineIterationInfo: $($ErrorRecord.PipelineIterationInfo)"
   }
   Write-Warning -Message "ScriptStackTrace:      $($ErrorRecord.ScriptStackTrace)"
   if ($ErrorRecord.TargetObject -ne $null) {
      Write-Warning -Message "TargetObject:          $($ErrorRecord.TargetObject)"
   }

# InvocationInfo

   Write-Warning -Message 'InvocationInfo:'

   Write-Warning -Message "   BoundParameters:       $($ErrorRecord.InvocationInfo.BoundParameters)"
   Write-Warning -Message "   CommandOrigin:         $($ErrorRecord.InvocationInfo.CommandOrigin)"
   Write-Warning -Message "   DisplayScriptPosition: $($ErrorRecord.InvocationInfo.DisplayScriptPosition)"
   Write-Warning -Message "   ExpectingInput:        $($ErrorRecord.InvocationInfo.ExpectingInput)"
   Write-Warning -Message "   HistoryId:             $($ErrorRecord.InvocationInfo.HistoryId)"
   Write-Warning -Message "   InvocationName:        $($ErrorRecord.InvocationInfo.InvocationName)"
   Write-Warning -Message "   Line:                  $($ErrorRecord.InvocationInfo.Line)"
   Write-Warning -Message "   MyCommand:             $($ErrorRecord.InvocationInfo.MyCommand)"
   Write-Warning -Message "   MyCommand.Name:        $($ErrorRecord.InvocationInfo.MyCommand.Name)"
   Write-Warning -Message "   OffsetInLine:          $($ErrorRecord.InvocationInfo.OffsetInLine)"
   Write-Warning -Message "   PipelineLength:        $($ErrorRecord.InvocationInfo.PipelineLength)"
   Write-Warning -Message "   PipelinePosition:      $($ErrorRecord.InvocationInfo.PipelinePosition)"
   Write-Warning -Message "   PositionMessage:       $($ErrorRecord.InvocationInfo.PositionMessage)"
   Write-Warning -Message "   PSCommandPath:         $($ErrorRecord.InvocationInfo.PSCommandPath)"
   Write-Warning -Message "   PSScriptRoot:          $($ErrorRecord.InvocationInfo.PSScriptRoot)"
   Write-Warning -Message "   ScriptLineNumber:      $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
   Write-Warning -Message "   ScriptName:            $($ErrorRecord.InvocationInfo.ScriptName)"
   Write-Warning -Message "   UnboundArguments:      $($ErrorRecord.InvocationInfo.UnboundArguments)"

#>

   Write-Warning -Message ($ErrorRecord.ToString(), $ErrorRecord.InvocationInfo.PositionMessage -join [Environment]::NewLine)
   Write-Error -ErrorRecord $ErrorRecord -CategoryActivity $ErrorRecord.CategoryInfo.Activity -CategoryReason $ErrorRecord.CategoryInfo.Reason -CategoryTargetName $ErrorRecord.CategoryInfo.TargetName -CategoryTargetType $ErrorRecord.CategoryInfo.TargetType

}

function Set-DotNetDataConfiguration {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(ParameterSetName = 'System', Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $System,
      [Parameter(ParameterSetName = 'User', Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $User,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [ValidateSet( 'MySQL', 'PostgreSQL' )]
      [String] $DBMS
   )
   DynamicParam {

      [Management.Automation.RuntimeDefinedParameterDictionary] $paramDict = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameterDictionary'
      [Collections.ObjectModel.Collection[System.Attribute]] $attribCollection = New-Object -TypeName 'Collections.ObjectModel.Collection[System.Attribute]'

      [Collections.Generic.Dictionary[[String], [Type]]] $paramNameTypeDict = New-Object -TypeName 'Collections.Generic.Dictionary[[String], [Type]]'

      switch -Exact ($DBMS) {

         'MySQL' {
            $paramNameTypeDict['DllPath'] = [String]
         }

         'PostgreSQL' {
            $paramNameTypeDict['DllPath'] = [String]
         }

         default {
            Write-Error -Message "$($MyInvocation.MyCommand.Name): Unrecognized DBMS '${DBMS}'" -CategoryReason 'Coding error in module!' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'ModuleFile'
         }

      } # switch -Exact ($DBMS)

      $paramNameTypeDict.Keys | % {
         [String] $paramName = $_
         [Type] $paramType = $paramNameTypeDict[$paramName]
         $attribCollection.Clear()
         [Management.Automation.ParameterAttribute] $attrib = New-Object -TypeName 'Management.Automation.ParameterAttribute'
         $attrib.ParameterSetName = '__AllParameterSets'
         $attrib.Mandatory = $true
         $attribCollection.Add($attrib)
         [Management.Automation.RuntimeDefinedParameter] $param = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameter' ($paramName, $paramType, $attribCollection)
         $paramDict.Add($paramName, $param)
      }

      return $paramDict
   } # DynamicParam

   Begin {
   }

   Process {

      [Boolean] $ok = $true

      [Boolean] $hasDllPath = $false

      switch -Exact ($DBMS) {

         'MySQL' {
            $hasDllPath = $true
         }

         'PostgreSQL' {
            $hasDllPath = $true
         }

         default {
            Write-Error -Message "$($MyInvocation.MyCommand.Name): Unrecognized DBMS '${DBMS}'" -CategoryReason 'Coding error in module!' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'ModuleFile'
         }

      } # switch -Exact ($DBMS)

      if ($hasDllPath) {
         [String] $DllPath = $PSBoundParameters['DllPath']
         if ( -not ( Test-Path -LiteralPath $DllPath ) ) {
            Write-Error -Message "$($MyInvocation.MyCommand.Name): DllPath '${DllPath}' not found." -CategoryReason 'DLL not found' -CategoryTargetName $DllPath -CategoryTargetType 'File'
            $ok = $false
         }
         [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
            DllPath = $DllPath
         }
      } # if ($hasDllPath)

      if ($ok) {
         Write-DotNetDataConfiguration -SystemOrUser $PSCmdlet.ParameterSetName -DBMS $DBMS -InputObject $obj
      }

   }

   End {
   }

}

function New-DataSet {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [String[]] $DataSetName = ( , 'data' )
   ) # Param

   Begin {
   }

   Process {

      $DataSetName | % {
         $dsname = $_

         [Data.DataSet] $dataset = New-Object -TypeName 'Data.DataSet' ($dsname)
         Write-Output -InputObject $dataset

      }

   }

   End {
   }

}

<# If there are any parameters, all Connections must be the same type as for the first Connection #>

<# PgSqlType enumeration values:
   Row
   Array
   LargeObject
   Boolean
   ByteA
   BigInt
   SmallInt
   Int
   Text
   Json
   Xml
   Point
   LSeg
   Path
   Box
   Polygon
   Line
   CIdr
   Real
   Double
   Circle
   MacAddr8
   Money
   MacAddr
   Inet
   Char
   VarChar
   Date
   Time
   TimeStamp
   TimeStampTZ
   Interval
   TimeTZ
   Bit
   VarBit
   Numeric
   Uuid
   JsonB
   IntRange
   NumericRange
   TimeStampRange
   TimeStampTZRange
   DateRange
   BigIntRange
#>

function New-DataAdapter {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbDataAdapter])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [AllowNull()]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $Query = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:DefaultCommandTimeout,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   ) # Param
   DynamicParam {

      [Management.Automation.RuntimeDefinedParameterDictionary] $paramDict = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameterDictionary'
      [Collections.ObjectModel.Collection[System.Attribute]] $attribCollection = New-Object -TypeName 'Collections.ObjectModel.Collection[System.Attribute]'

      [String] $paramName = 'ParameterTypeDictionary'

      [Data.Common.DbConnection] $conn = $Connection[0]
      switch -Exact ($conn.GetType()) {
         'MySql.Data.MySqlClient.MySqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[String], [MySql.Data.MySqlClient.MySqlDbType]]]
         }
         'Devart.Data.PostgreSql.PgSqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[String], [Devart.Data.PostgreSql.PgSqlType]]]
         }
         'System.Data.SqlClient.SqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[String], [Data.SqlDbType]]]
         }
         default {
            Write-Error -Message "$($MyInvocation.MyCommand.Name): Unrecognized Connection type '$($conn.GetType())'" -CategoryReason 'Coding error in module!' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'ModuleFile'
            [Type] $paramType = $null
         }
      }

      if ($paramType -ne $null) {

         $attribCollection.Clear()
         [Management.Automation.ParameterAttribute] $attrib = New-Object -TypeName 'Management.Automation.ParameterAttribute'
         $attrib.ParameterSetName = '__AllParameterSets'
<#
         $attrib.Mandatory = $false
#>
         $attribCollection.Add($attrib)

         [Management.Automation.RuntimeDefinedParameter] $param = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameter' ($paramName, $paramType, $attribCollection)

         $paramDict.Add($paramName, $param)

      }

      return $paramDict
   } # DynamicParam

   Begin {

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      $nNull = 0
      $nConn = 0

   }

   Process {

      $ParameterTypeDictionary = $PSBoundParameters['ParameterTypeDictionary']

      $Connection | % {
         if ($_ -eq $NULL) {
            $nNull += 1
            $nConn += 1
         }
         else {
            [Data.Common.DbConnection] $conn = $_
            $nConn += 1

            switch -Exact ($conn.GetType()) {
               'MySql.Data.MySqlClient.MySqlConnection' {
                  $cmdClass = 'MySql.Data.MySqlClient.MySqlCommand'
                  $daClass = 'MySql.Data.MySqlClient.MySqlDataAdapter'
               }
               'Devart.Data.PostgreSql.PgSqlConnection' {
                  $cmdClass = 'Devart.Data.PostgreSql.PgSqlCommand'
                  $daClass = 'Devart.Data.PostgreSql.PgSqlDataAdapter'
               }
               'System.Data.SqlClient.SqlConnection' {
                  $cmdClass = 'Data.SqlClient.SqlCommand'
                  $daClass = 'Data.SqlClient.SqlDataAdapter'
               }
               default {
                  Write-Error -Message "$($MyInvocation.MyCommand.Name): Connection Class '$($conn.GetType())' not recognized" -CategoryReason 'Coding error in module!' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'ModuleFile'
               }
            }

            $cmd = New-Object -TypeName $cmdClass
            $cmd.Connection = $conn
            $cmd.CommandTimeout = $CommandTimeout
            $cmd.CommandText = $Query
            if ($cmd.PSObject.Properties.Name -contains 'UpdateBatchSize') {
               $cmd.UpdateBatchSize = 0 # unlimited
                  # requires .NET Framework 2.0 or later - https://docs.microsoft.com/en-us/dotnet/api/system.data.common.dbdataadapter.updatebatchsize?view=netframework-2.0
            }

            if ($ParameterTypeDictionary -ne $NULL) {
               $ParameterTypeDictionary.Keys | % {
                  $key = $_
                  [void] $cmd.Parameters.Add($key, $ParameterTypeDictionary[$key])
               }
            }

            $da = New-Object -TypeName $daClass

            $da.SelectCommand = $cmd
            [Management.Automation.CallStackFrame] $csfTryCatch1 = (gcs)[0]; Try {
               $da.UpdateBatchSize = 0 # unlimited
                  # requires .NET Framework 2.0 or later - https://docs.microsoft.com/en-us/dotnet/api/system.data.common.dbdataadapter.updatebatchsize?view=netframework-2.0
                  # but fails on .NET Framework v4.8.03761
            } # Try
            Catch {
               [Management.Automation.ErrorRecord] $er1 = $_
               [String] $msg = "$($MyInvocation.MyCommand.Name): Assigning to DbDataAdapter.UpdateBatchSize failed on PowerShell Version $( ( Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' ).Version )"
               [String] $functionAndScriptLocation = "in $($csfTryCatch1.FunctionName) at $($csfTryCatch1.ScriptName): $($csfTryCatch1.ScriptLineNumber)"
               Write-Warning -Message ( $msg, $functionAndScriptLocation -join [Environment]::NewLine)
            } # Catch

            Write-Output -InputObject $da

         }

      }

   }

   End {
      if ($nNull -gt 0) {
         if ($nNull -lt $nConn) {
            [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): ${nNull} of ${nConn} connections are null"
         }
         elseif ($nConn -eq 1) {
            [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): Connection is null"
         }
         else {
            [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): All ${nConn} connections are null"
         }
         Write-Warning -Message ($msgs -join [Environment]::NewLine)
      }
   }

}

function Get-Rows {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
   [OutputType([Data.DataRow[]])]
   Param(
      [Parameter(ParameterSetName = 'FirstResultSet', Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Data.Common.DbDataAdapter[]] $DataAdapter = $NULL,
      [Parameter(ParameterSetName = 'FirstResultSet', Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [Parameter(ParameterSetName = 'NextResultSet', Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Data.DataSet[]] $DataSet,
      [Parameter(ParameterSetName = 'FirstResultSet', Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [Parameter(ParameterSetName = 'NextResultSet', Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $DataSetIndex = 0,
      [Parameter(ParameterSetName = 'FirstResultSet', Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [Parameter(ParameterSetName = 'NextResultSet', Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $TableIndex = 0,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      if ($DataAdapter -ne $NULL) {

         if (1, $DataAdapter.Count -notcontains $DataSet.Count) {
            Write-Error -Message "$($MyInvocation.MyCommand.Name): Number of DataSet elements ($($DataSet.Count)) must be 1 or match the number of DataAdapter elements ($($DataAdapter.Count))" -CategoryReason 'Invalid parameter' -CategoryTargetName 'DataSet' -CategoryTargetType 'Parameter'
         }

         if ($DataSet.Count -eq 1) {
            $DataSet[0].Clear()
         }

      }

   }

   Process {

      [Boolean] $ok = $true

      if ($DataAdapter -ne $NULL) {

         for ($i = 0; $i -lt $DataAdapter.Count; $i += 1) {
            $da = $DataAdapter[$i]

            if ($DataSet.Count -eq 1) {
               $ds = $DataSet[0]
               $msgDataSet = "DataSet"
            }
            else {
               $ds = $DataSet[$i]
               $ds.Clear()
               $msgDataSet = "DataSet[${i}]"
            }
            if ($ds -eq $null) {
               Write-Error -Message "$($MyInvocation.MyCommand.Name): ${msgDataSet} is null" -CategoryReason 'DataSet is null' -CategoryTargetName $msgDataSet -CategoryTargetType 'DataSet'
               [Boolean] $ok = $false
            }
            else {

               [Data.Common.DbCommand] $cmd = $da.SelectCommand
               if ($cmd -eq $NULL) {
                  $msg = "$($MyInvocation.MyCommand.Name): Command has not been set in DataAdapter"
                  Write-Error -Message $msg -CategoryReason 'Command not set' -CategoryTargetName 'SelectCommand' -CategoryTargetType 'Command'
               }

               if ($cmd.Connection.State -ne 'Open') {
                  Write-Error -Message "$($MyInvocation.MyCommand.Name): Connection to instance `"$($cmd.Connection.DataSource)`" is not 'Open'" -CategoryReason 'Connection not Open' -CategoryTargetName $cmd.Connection.DataSource -CategoryTargetType 'DataSource'
                  if ($DataAdapter.Count -eq 1) {
                     [Boolean] $ok = $false
                  }
# TO DO:          # else return data from other instances
               }
               else {
                  [Management.Automation.CallStackFrame] $csfTryCatch1 = (gcs)[0]; Try {
                     [int] $nRows = $da.Fill($ds)
                        # nRows - number of rows in first DataTable
                  } # Try
                  Catch {
                     [Management.Automation.ErrorRecord] $er1 = $_
                     Write-Error -ErrorRecord $er1 -CategoryReason 'DataAdapter.Fill threw exception' -CategoryTargetName $cmd.Connection.DataSource -CategoryTargetType 'DataSource'
                     [Boolean] $ok = $false
                  } # Catch
               }

            }
         }

      }

      if ($ok) {

         if ($DataSetIndex -ge $DataSet.Count) {
            Write-Warning -Message "$($MyInvocation.MyCommand.Name): DataSetIndex ${DataSetIndex} not valid. DataSet.Count=$($DataSet.Tables.Count)"
            Write-Output -InputObject $NULL
         }
         else {
            if ($DataSet.Count -eq 1) {
               [String] $msgDataSet = "DataSet"
            }
            else {
               [String] $msgDataSet = "DataSet[${DataSetIndex}]"
            }
            if ($TableIndex -ge $DataSet[$DataSetIndex].Tables.Count) {
               Write-Warning -Message "$($MyInvocation.MyCommand.Name): TableIndex ${TableIndex} not valid. ${msgDataSet}.Tables.Count=$($DataSet[$DataSetIndex].Tables.Count)"
               Write-Output -InputObject $NULL
            }
            else {
               [Data.DataTable] $table = $Dataset[$DataSetIndex].Tables[$TableIndex]
               Write-Output -InputObject $table.Rows
            }
         }

      }

   }

   End {
   }

}

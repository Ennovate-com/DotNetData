<# DotNetData/Public/Common/ExportTable.ps1
#>

function Export-Table {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $TableName,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String[]] $OutputDirPath,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:DefaultCommandTimeout
   )

   Begin {

      [bool] $append = $false

   } # Begin

   Process {

      $Connection | % {
         [Data.Common.DbConnection] $conn = $_

         $TableName | % {
            [String] $tblName = $_

         # Get qualified and unqualified table names

            if ($tblName -match '^(?:\[.+\]\.)?\[(.+)\]$') {
               [String] $qualTableName = $tblName
               [String] $unqualTableName = $Matches[1]
            }
            elseif ($tblName -match '^(?:([^\.]+)\.)?([^\.]+)$') {
               if ($Matches[1] -eq $null) {
                  [String] $qualTableName = ConvertTo-SqlQuotedName -Name $Matches[2]
               }
               elseif ($Matches[1] -like '`[*`]') {
                  [String] $qualTableName = "$($Matches[1]).$(ConvertTo-SqlQuotedName -Name $Matches[2])"
               }
               else {
                  [String] $qualTableName = "$(ConvertTo-SqlQuotedName -Name $Matches[1]).$(ConvertTo-SqlQuotedName -Name $Matches[2])"
               }
               [String] $unqualTableName = $Matches[2]
            }
            else {
               Write-Error -Message "More than two-level names currently not supported - TableName: ${tblName}"
               return
            }
            Write-Verbose -Message "Export-Table ${qualTableName}"

            [DateTime] $startTime = Get-Date

         # Get metadata for table

            [Data.Common.DbDataAdapter] $da = New-DataAdapter -Connection $conn -Query "select * from $qualTableName;" -CommandTimeout $CommandTimeout

            [Data.DataSet] $ds = New-Object -TypeName 'Data.DataSet' -ArgumentList "${unqualTableName}_data"
            [Data.SchemaType] $schemaType = [Data.SchemaType]::Source
               # ignore any mappings on the DataAdapter
            [String] $srcTable = "${unqualTableName}_Table"
            [Data.CommandBehavior] $behavior = [Data.CommandBehavior]::SchemaOnly -bor [Data.CommandBehavior]::KeyInfo
            [Data.DataTable[]] $dts  = $da.FillSchema($ds, $schemaType, $srcTable)

         # Create query with column names

            [Collections.Generic.List[String]] $cols = New-Object -TypeName 'Collections.Generic.List[String]]'
            $dts[0].Columns | % {
               [Data.DataColumn] $col = $_
               [void] $cols.Add( (ConvertTo-SqlQuotedName -Name $col.ColumnName) )
            }

            $da.SelectCommand.CommandText = "select $($cols -join ', ') from $qualTableName;"
            try {
               [int] $nRows = $da.Fill($ds)
                  # nRows - number of rows in first DataTable
               Write-Verbose "   $($dts.Count) table, ${nRows} row(s), $($dts[0].Columns.Count) columns"
            } # try
            catch {
               [Management.Automation.ErrorRecord] $er1 = $_
               Write-Error -ErrorRecord $er1 -CategoryReason 'DataAdapter.Fill threw exception' -CategoryTargetName $cmd.Connection.DataSource -CategoryTargetType 'DataSource'
               [Boolean] $ok = $false
            } # catch

            [String] $outFilePath = Join-Path -Path $OutputDirPath -ChildPath "${unqualTableName}.txt"
            $ds.Tables[1] | Select-Object * -ExcludeProperty 'RowError', 'RowState', 'Table', 'ItemArray', 'HasErrors' | Export-Csv -LiteralPath $outFilePath -Delimiter "`t" -Encoding 'UTF8' -NoTypeInformation -Force

         # Show duration

            [TimeSpan] $ts = New-TimeSpan -Start $startTime
            [String] $duration = Convert-TimeSpanToString $ts
            Write-Warning -Message "Exported ${nRows} row(s) from ${qualTableName} in ${duration}"

         }

      }

      $append = $true

   } # Process

   End {
   }

} # function Export-Table

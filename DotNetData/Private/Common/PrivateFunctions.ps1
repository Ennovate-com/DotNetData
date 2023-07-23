<#
   System Configuration File Location: C:\ProgramData\DotNetData\
   User Configuration File Location:   $($env:USERPROFILE)\AppData\Local\DotNetData\
   Configuration File Name:            DotNetData_config.json
#>

[String] $Script:ConfigDirName = 'DotNetData'
[String] $Script:ConfigFileName = 'DotNetData_config.json'

[Collections.Generic.Dictionary[String, Object]] $Script:Configuration = New-Object -TypeName 'Collections.Generic.Dictionary[String, Object]'

function Write-DotNetDataConfiguration {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $SystemOrUser,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $DBMS,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $true)]
      [Object] $InputObject
   )

   [String] $userAppDataDirPath = [Environment]::GetFolderPath('LocalApplicationData')
   [String] $userConfigDirPath = Join-Path -Path $userAppDataDirPath -ChildPath 'DotNetData'
   [String] $userConfigFilePath = Join-Path -Path $userConfigDirPath -ChildPath $Script:ConfigFileName

   switch -Exact ($SystemOrUser) {
      'System' {
         [String] $appdataDirPath = [Environment]::GetFolderPath('CommonApplicationData')
         [String] $configDirPath = Join-Path -Path $appdataDirPath -ChildPath 'DotNetData'
         [String] $configFilePath = Join-Path -Path $configDirPath -ChildPath $Script:ConfigFileName
         [Boolean] $checkForUserConfig = $true
      }
      'User' {
         [String] $configDirPath = $userConfigDirPath
         [String] $configFilePath = $userConfigFilePath
         [Boolean] $checkForUserConfig = $false
      }
      default {
         Write-Error -Message "$($MyInvocation.MyCommand.Name): Unrecognized SystemOrUser '${SystemOrUser}'" -CategoryReason 'Coding error in module!' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'ModuleFile'
      }
   }

   if ( Test-Path -LiteralPath $configFilePath ) {
      [Object[]] $configJSON = Get-Content -Path $configFilePath
      [Object] $config = $configJSON | ConvertFrom-Json
   }
   else {

   # Make sure directory exists

      if ( -not ( Test-Path -LiteralPath $configDirPath -PathType 'Container' ) ) {
         [IO.DirectoryInfo] $dir = New-Item -Path $configDirPath -ItemType 'Directory'
      }

   # Initialize configuration

      [Object] $config = New-Object -TypeName 'PSObject'

   }
   [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $config -Name $DBMS
   if ($member -eq $null) {
      Add-Member -InputObject $config -MemberType 'NoteProperty' -Name $DBMS -Value $InputObject
   }
   else {
      $config.$DBMS = $InputObject
   }

   Write-Verbose -Message "Writing configuration file '${configFilePath}'"
   $config | ConvertTo-Json | Out-File $configFilePath -Encoding UTF8

<# Same DBMS in User configuration file overrides entire DBMS in System configuration file #>

   if ($checkForUserConfig) {
      if ( Test-Path -LiteralPath $userConfigFilePath ) {
         [Object[]] $userConfigJSON = Get-Content -Path $userConfigFilePath
         [Object] $userConfig = $userConfigJSON | ConvertFrom-Json
         [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $userConfig -Name $DBMS
         if ($member -ne $null) {
            Write-Warning -Message "User configuration for ${DBMS} also exists; will override System configuration"
         }
      }
   }

}

function Get-DotNetDataConfiguration {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $DBMS
   )

   [Boolean] $missingConfig = $true

# User-specific configuration file

   [String] $appdataDirPath = [Environment]::GetFolderPath('LocalApplicationData')
   [String] $configDirPath = Join-Path -Path $appdataDirPath -ChildPath 'DotNetData'
   [String] $configFilePath = Join-Path -Path $configDirPath -ChildPath $Script:ConfigFileName
   if ( Test-Path -LiteralPath $configFilePath ) {
      [Object[]] $configJSON = Get-Content -Path $configFilePath
      [Object] $config = $configJSON | ConvertFrom-Json
      [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $config -Name $DBMS
      if ($member -ne $null) {
         [Object] $dbmsConfig = $config.$DBMS
         Write-Output -InputObject $dbmsConfig
         $missingConfig = $false
      }
   }

# System-wide configuration file

   if ($missingConfig) {

      [String] $appdataDirPath = [Environment]::GetFolderPath('CommonApplicationData')
      [String] $configDirPath = Join-Path -Path $appdataDirPath -ChildPath 'DotNetData'
      [String] $configFilePath = Join-Path -Path $configDirPath -ChildPath $Script:ConfigFileName
      if ( Test-Path -LiteralPath $configFilePath ) {
         [Object[]] $configJSON = Get-Content -Path $configFilePath
         [Object] $config = $configJSON | ConvertFrom-Json
         [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $config -Name $DBMS
         if ($member -ne $null) {
            [Object] $dbmsConfig = $config.$DBMS
            Write-Output -InputObject $dbmsConfig
            $missingConfig = $false
         }
      }

   }

   if ($missingConfig) {
      Write-Error -Message "Configuration for ${DBMS} not found. Use 'Set-DotNetDataConfiguration' to create it." -CategoryReason 'Missing configuration' -CategoryTargetName $Script:ConfigFileName -CategoryTargetType 'File'
   }

}

function Import-Dll {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Management.Automation.PSCredential])]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String] $DllPath
   )

   [String] $dllFileName = Split-Path $DllPath -Leaf
   [String] $assemblyName = $dllFileName.Replace('.dll', '')

# Load DLL

   if ( -not ( Test-Path -LiteralPath $dllPath ) ) {
      Write-Error -Message "$($MyInvocation.MyCommand.Name): ${dllFileName} not found at '${DllPath}' - specify correct path in DllPath parameter or add it to paths being searched" -CategoryReason 'Invalid DllPath' -CategoryTargetName 'DllPath' -CategoryTargetType 'Parameter'
   }

# Load the DLL

   if (([AppDomain]::CurrentDomain.GetAssemblies() | Select-Object -Property @{ n='ShortName'; e={$_.FullName.Substring(0, $_.FullName.IndexOf(','))} }).ShortName -contains $assemblyName) {
      Write-Verbose -Message "$($MyInvocation.MyCommand.Name): ${assemblyName} assembly already loaded"
   } # if (already loaded)
   else { # needs loaded
      [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
         [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; if (Test-Path -LiteralPath $DllPath) {
            [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; [void] [Reflection.Assembly]::LoadFrom($DllPath)
            # or [System.Reflection.Assembly]::LoadWithPartialName($assemblyName)
         }
         else {
            Write-Error -Message "$($MyInvocation.MyCommand.Name): ${dllFileName} not found at '${DllPath}' - specify correct path in DllPath parameter or add it to paths being searched" -CategoryReason 'Invalid DllPath' -CategoryTargetName 'DllPath' -CategoryTargetType 'Parameter'
         }
      }
      catch {
         [Management.Automation.ErrorRecord] $ex = $_
         $errstr = Write-Message -Message "[Reflection.Assembly]::LoadFrom('$DllPath')" -ErrorRecord $ex $Global:ErrorCount -CallStackFrame $csfTryCatchLine
         Write-Error -Message "$($MyInvocation.MyCommand.Name): Failed to load ${dllFileName}. ${errstr}" -CategoryReason 'Invalid DllPath' -CategoryTargetName 'DllPath' -CategoryTargetType 'Parameter'
      }
   } # else (needs loaded)

}

function Get-CredentialForUserName {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Management.Automation.PSCredential])]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [AllowEmptyString()]
      [String] $LogFilePath = [NullString]::Value,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   if ($CallStackFrame -eq $NULL) {
      [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
   }

   [String] $userProfile = $env:USERPROFILE
   if ($userProfile -eq 'C:\Users\Default') {
      [String] $whoami = whoami
      Write-Warning -Message "env:USERPROFILE should not be '$($userProfile)' env:USERNAME='$($env:USERNAME)' whoami = '${whoami}'", 'User''s profile might be missing.', "Start Command Prompt with `"Run as a different user`" using '$($env:USERDOMAIN)\$($env:USERNAME)' and run again while Command Prompt is still open to create the user`s profile."
   }

   [String] $credPath = Join-Path -Path $env:USERPROFILE -ChildPath 'Credentials' | Join-Path -ChildPath "${UserName}.pwd"
   [Boolean] $exists = Test-Path -LiteralPath $credPath -PathType 'Leaf'
   if ($exists) {
      [Security.SecureString] $password = Get-Content -LiteralPath $credPath -Encoding 'utf8' | ConvertTo-SecureString
      if ($password -eq $null) {
         [String] $msg = "Null value retrieved from password file `"${credPath}`""
         Write-Error -Message "$($MyInvocation.MyCommand.Name): ${msg}" -CategoryReason 'Null password' -CategoryTargetName '(null)' -CategoryTargetType 'Password'
      }
      else {
         [Management.Automation.PSCredential] $cred = New-Object -TypeName 'Management.Automation.PSCredential' ($username, $password)
         Write-Output -InputObject $cred
      }
   }
   else {
      [String] $msg = "Missing password file `"${credPath}`""
      Write-Error -Message "$($MyInvocation.MyCommand.Name): ${msg}" -CategoryReason 'Missing password file' -CategoryTargetName $credPath -CategoryTargetType 'File'
   }

}

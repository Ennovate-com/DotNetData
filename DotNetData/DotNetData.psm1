<# DotNetData.psm1
#>

$verbosePref = $Global:VerbosePreference
$Global:VerbosePreference = 'Continue'

Set-PSDebug -Strict              # Global scope, variables must be assigned a value before being referenced
Set-StrictMode -Version 'Latest' # Current and child scopes

[int] $Script:DefaultCommandTimeout = 300 # default is 30

# Get arrays of private and public source FileSpace

[IO.FileInfo[]] $pvtFileInfo = Get-ChildItem -Path (Join-Path $PSScriptRoot Private) -Include *.ps1 -File -Recurse
[IO.FileInfo[]] $pubFileInfo = Get-ChildItem -Path (Join-Path $PSScriptRoot Public) -Include *.ps1 -File -Recurse 

# Source in the source files

($pvtFileInfo + $pubFileInfo) | % {
   [IO.FileInfo] $fileInfo = $_
   
   Try {
      Write-Verbose -Message "Sourcing $($fileInfo.FullName)"
      . $fileInfo.FullName
   } # Try
   Catch {
      [Management.Automation.ErrorRecord] $er = $_
      Write-Error -ErrorRecord $er -CategoryReason 'dot source threw exception' -CategoryTargetName $fileInfo.Name -CategoryTargetType 'File'
   } # Catch

}

<# Additional code here to:
   Create or read a config file
   Set variables visible only to the module's functions
   etc.
#>

$Global:VerbosePreference = $verbosePref

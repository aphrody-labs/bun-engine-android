$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
foreach ($Name in @('JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'ANDROID_NDK_HOME', 'ANDROID_NDK_ROOT', 'GHIDRA_INSTALL_DIR', 'GHIDRA_HOME', 'GRADLE_HOME')) {
    $Value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if ([Environment]::GetEnvironmentVariable($Name, 'User') -ne $Value) {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    }
}
$ExistingPath = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
$NewPath = (($ToolPaths + $ExistingPath | Where-Object { $_ }) | Select-Object -Unique) -join ';'
if ([Environment]::GetEnvironmentVariable('Path', 'User') -ne $NewPath) {
    [Environment]::SetEnvironmentVariable('Path', $NewPath, 'User')
}
Write-Output 'Android environment and user PATH configured.'

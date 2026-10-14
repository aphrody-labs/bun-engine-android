param([switch]$Connected, [switch]$WriteLocks, [int]$TimeoutSeconds = 900)
$ErrorActionPreference = 'Stop'
$Workspace = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
. (Join-Path $Workspace 'scripts/env.ps1')
$Arguments = @('assembleDebug', 'assembleDebugAndroidTest', 'testDebugUnitTest', 'lintDebug', '--no-daemon', '--console=plain')
if ($Connected) { $Arguments += 'connectedDebugAndroidTest' }
if ($WriteLocks) { $Arguments += '--write-locks' }
$Process = Start-Process -FilePath (Join-Path $env:GRADLE_HOME 'bin/gradle.bat') -ArgumentList $Arguments -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput "$Workspace/logs/compose-build.log" -RedirectStandardError "$Workspace/logs/compose-build.stderr.log"
$ProcessHandle = $Process.Handle
if (!$Process.WaitForExit($TimeoutSeconds * 1000)) {
    $Process.Kill($true)
    throw "Compose verification exceeded $TimeoutSeconds seconds"
}
$Process.Refresh()
if ($Process.ExitCode -ne 0) { throw "Compose verification failed: $($Process.ExitCode). See logs/compose-build.log and logs/compose-build.stderr.log" }
Write-Output 'COMPOSE_BUILD_UNIT_LINT_PASS'
if ($Connected) { Write-Output 'COMPOSE_CONNECTED_TESTS_PASS' }

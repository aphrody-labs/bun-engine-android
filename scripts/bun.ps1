param(
    [Parameter(Position=0)][string]$Action = 'doctor',
    [Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'env.ps1')
$workspace = Split-Path $PSScriptRoot -Parent
$checkout = if ($env:APHRODY_BUN_CHECKOUT) { $env:APHRODY_BUN_CHECKOUT } else { Join-Path (Split-Path $workspace -Parent) 'bun' }
$runtime = if ($env:ANDROID_BUN_BIN) { $env:ANDROID_BUN_BIN } else { Join-Path $checkout 'build\release\bun.exe' }
if (-not (Test-Path -LiteralPath $runtime)) { throw 'Bun 1.4.4 native owner build missing. Configure ANDROID_BUN_BIN or APHRODY_BUN_CHECKOUT.' }
$version = & $runtime --version
if ($version -notmatch '^1\.4\.4(?:-|$)') { throw "Expected Bun 1.4.4, found $version" }
$package = Join-Path $workspace 'packages\android-web'
$commands = @{
    build = @('run', 'build')
    test = @('test')
    doctor = @('run', 'android:doctor')
    dev = @('run', 'dev')
    devices = @('run', 'android:devices')
    install = @('run', 'android:install')
    sdk = @('run', 'android:sdk')
    ffi = @('run', 'ffi')
    'docs-sync' = @('run', 'src/cli.ts', 'sync')
    'docs-check' = @('run', 'src/cli.ts', 'check')
    'docs-test' = @('test')
}
if (-not $commands.ContainsKey($Action)) { throw "Unknown Bun workspace action: $Action" }
if ($Action.StartsWith('docs-')) { $package = Join-Path $workspace 'packages\docs-sync' }
Push-Location -LiteralPath $package
$previousPath = $env:PATH
$env:PATH = (Split-Path $runtime -Parent) + [IO.Path]::PathSeparator + $previousPath
try {
    & $runtime @($commands[$Action]) @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Bun $Action failed ($LASTEXITCODE)" }
} finally {
    $env:PATH = $previousPath
    Pop-Location
}

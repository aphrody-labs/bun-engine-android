$ErrorActionPreference = 'Stop'
$jdkRoot = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'tools\jdk-latest'
$jdk = Get-ChildItem -LiteralPath $jdkRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'bin\javac.exe') } | Select-Object -First 1
if (-not $jdk) { throw 'Latest JDK is not installed' }
$classes = Join-Path $PSScriptRoot 'classes'
New-Item -ItemType Directory -Force -Path $classes | Out-Null
& (Join-Path $jdk.FullName 'bin\javac.exe') -version
if ($LASTEXITCODE -ne 0) { throw 'javac version failed' }
& (Join-Path $jdk.FullName 'bin\javac.exe') -d $classes (Join-Path $PSScriptRoot 'HelloLatest.java')
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed' }
& (Join-Path $jdk.FullName 'bin\java.exe') -cp $classes HelloLatest
if ($LASTEXITCODE -ne 0) { throw 'Execution failed' }

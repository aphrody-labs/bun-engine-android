param([int]$TimeoutSeconds = 900)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
& "$PSScriptRoot\build-rust.ps1" -TimeoutSeconds $TimeoutSeconds
Push-Location "$AndroidWorkspace\packages\android-web"
try {
    & "$PSScriptRoot\bun.ps1" build
    if ($LASTEXITCODE -ne 0) { throw 'Bun bundle failed' }
} finally { Pop-Location }
$Gradle = Join-Path $env:GRADLE_HOME 'bin\gradle.bat'
$Build = Start-Process -FilePath $Gradle -ArgumentList @('-p', "$AndroidWorkspace\apps\android", 'assembleDebug', '--no-daemon', '--console=plain') -WindowStyle Hidden -PassThru -RedirectStandardOutput "$AndroidWorkspace\logs\android-build.log" -RedirectStandardError "$AndroidWorkspace\logs\android-build.stderr.log"
$BuildHandle = $Build.Handle
if (!$Build.WaitForExit($TimeoutSeconds * 1000)) { throw "Android build remains active, PID $($Build.Id), after $TimeoutSeconds seconds" }
if ($Build.ExitCode -ne 0) { throw "Android build failed: $($Build.ExitCode), see logs/android-build.log" }
$Apk = "$AndroidWorkspace\apps\android\app\build\outputs\apk\debug\app-debug.apk"
if (!(Test-Path $Apk)) { throw 'Missing APK' }
& "$env:ANDROID_HOME\build-tools\37.0.0\apksigner.bat" verify --verbose $Apk
if ($LASTEXITCODE -ne 0) { throw 'APK signature verification failed' }
Write-Output "APK built and verified: $Apk"

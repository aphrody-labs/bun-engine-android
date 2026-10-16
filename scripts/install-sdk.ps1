$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Start-Transcript -Path "$Root\logs\sdk-install.log" -Append
function Get-VerifiedArchive($Url, $File, $Hash, $Algorithm = 'SHA256') {
    if (!(Test-Path $File)) {
        & curl.exe --fail --location --retry 3 --connect-timeout 20 --max-time 900 --output $File $Url
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $Url" }
    }
    if ((Get-FileHash $File -Algorithm $Algorithm).Hash -ne $Hash) { throw "Checksum mismatch: $File" }
}
$JdkArchive = "$Root\downloads\jdk21.zip"
Get-VerifiedArchive 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.12.1%2B1/OpenJDK21U-jdk_x64_windows_hotspot_21.0.12.1_1.zip' $JdkArchive 'f9d6e191ab098c0d416e7d588a24420a8621cd2f4720dab2459b8b7b2d2d8b4e'
if (!(Test-Path "$Root\tools\jdk\bin\java.exe")) {
    Expand-Archive $JdkArchive "$Root\tools\jdk-extract" -Force
    $Extracted = Get-ChildItem "$Root\tools\jdk-extract" -Directory | Select-Object -First 1
    Move-Item -LiteralPath $Extracted.FullName -Destination "$Root\tools\jdk"
    Remove-Item -LiteralPath "$Root\tools\jdk-extract"
}
$env:JAVA_HOME = "$Root\tools\jdk"
$env:ANDROID_HOME = "$Root\sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
$CliArchive = "$Root\downloads\cmdline-tools.zip"
Get-VerifiedArchive 'https://dl.google.com/android/repository/commandlinetools-win-16111833_latest.zip' $CliArchive '57d04f2d75eb8e8fffc5000a987e5de4b5a63e9d' 'SHA1'
if (!(Test-Path "$Root\sdk\cmdline-tools\latest\bin\sdkmanager.bat")) {
    Expand-Archive $CliArchive "$Root\sdk\cli-extract" -Force
    New-Item -ItemType Directory -Force "$Root\sdk\cmdline-tools" | Out-Null
    Move-Item -LiteralPath "$Root\sdk\cli-extract\cmdline-tools" -Destination "$Root\sdk\cmdline-tools\latest"
    Remove-Item -LiteralPath "$Root\sdk\cli-extract"
}
$Manager = "$Root\sdk\cmdline-tools\latest\bin\sdkmanager.bat"
$Android = "$Root\sdk\cmdline-tools\latest\bin\android.exe"
& $Android --no-metrics "--sdk=$Root\sdk" sdk install 'platform-tools' 'platforms/android-37.2' 'build-tools/37.0.0' 'ndk/30.0.16248370' 'cmake/4.1.2' 'emulator'
if ($LASTEXITCODE -ne 0) { throw 'SDK package installation failed' }
& $Android --no-metrics "--sdk=$Root\sdk" sdk list
foreach ($Package in @('platform-tools/adb.exe','platforms/android-37.2/android.jar','build-tools/37.0.0/aapt2.exe','ndk/30.0.16248370/source.properties','cmake/4.1.2/bin/cmake.exe','emulator/emulator.exe')) {
    if (!(Test-Path "$Root\sdk\$Package")) { throw "Missing SDK package: $Package" }
}
Stop-Transcript

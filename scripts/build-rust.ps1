param([int]$TimeoutSeconds = 900, [switch]$HostOnly)
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Project = Join-Path $Root 'crates/android-native'
$NdkRoot = Join-Path $Root 'sdk/ndk/30.0.16248370'
if (!$HostOnly -and !(Test-Path -LiteralPath "$NdkRoot/source.properties")) {
    throw "NDK installation incomplete: $NdkRoot/source.properties"
}
$env:ANDROID_NDK_HOME = $NdkRoot
$env:ANDROID_NDK_ROOT = $NdkRoot
$env:ANDROID_HOME = Join-Path $Root 'sdk'
$env:CARGO_TARGET_DIR = Join-Path $Root 'target/rust'
$Mutex = [System.Threading.Mutex]::new($false, 'Local\AphrodyAndroidCargoBuild')
$Acquired = $false
try {
    try { $Acquired = $Mutex.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $Acquired = $true }
    if (!$Acquired) { throw 'Another Android Cargo build is active.' }
    Start-Transcript -Path "$Root/logs/rust-build.log" -Append
    $Cargo = (Get-Command cargo.exe).Source
    $Arguments = if ($HostOnly) { @('+nightly', 'build', '-p', 'android-native', '--locked') } else { @('+nightly', 'ndk', '-t', 'arm64-v8a', '-t', 'armeabi-v7a', '-t', 'x86', '-t', 'x86_64', '--platform', '23', '-o', 'target/android/jniLibs', 'build', '-p', 'android-native', '--release', '--locked') }
    $Process = Start-Process -FilePath $Cargo -ArgumentList $Arguments -WorkingDirectory $Root -WindowStyle Hidden -PassThru -RedirectStandardOutput "$Project/cargo-build.stdout.log" -RedirectStandardError "$Project/cargo-build.stderr.log"
    $ProcessHandle = $Process.Handle
    if (!$Process.WaitForExit($TimeoutSeconds * 1000)) {
        $Process.Kill($true)
        throw "Cargo build exceeded $TimeoutSeconds seconds"
    }
    $Process.Refresh()
    Get-Content -LiteralPath "$Project/cargo-build.stdout.log"
    Get-Content -LiteralPath "$Project/cargo-build.stderr.log"
    if ($Process.ExitCode -ne 0) { throw "Cargo build failed: $($Process.ExitCode)" }
    if ($HostOnly) {
        if (!(Test-Path -LiteralPath "$Root/target/rust/debug/android_native.dll")) { throw 'Host DLL missing' }
        Write-Output "PASS Windows native DLL: $Root/target/rust/debug/android_native.dll"
        return
    }
    $ReadElf = Join-Path $NdkRoot 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe'
    $Expected = @{ 'arm64-v8a' = 'AArch64'; 'armeabi-v7a' = 'ARM'; 'x86' = 'Intel 80386'; 'x86_64' = 'Advanced Micro Devices X86-64' }
    foreach ($Abi in @('arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64')) {
        $Library = Join-Path $Root "target/android/jniLibs/$Abi/libandroid_native.so"
        $Header = (& $ReadElf --file-header $Library) -join "`n"
        if ($LASTEXITCODE -ne 0 -or $Header -notmatch [regex]::Escape($Expected[$Abi])) { throw "ELF architecture verification failed: $Abi" }
        $Symbols = (& $ReadElf --dyn-syms $Library) -join "`n"
        if ($LASTEXITCODE -ne 0 -or $Symbols -notmatch 'Java_com_aphrody_android_NativeBridge_add') { throw "JNI export missing: $Abi" }
        if ($Symbols -notmatch 'android_add') { throw "C FFI export missing: $Abi" }
        Write-Output "PASS $Abi ELF and JNI export: $Library"
    }
} finally {
    if ($Acquired) { $Mutex.ReleaseMutex() }
    $Mutex.Dispose()
    try { Stop-Transcript } catch {}
}

param([string]$Name='AphrodyAndroid37', [int]$DeviceTimeoutSeconds=180)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$sdk=Join-Path $root 'sdk'
$image='system-images;android-37.2;google_apis_ps16k;x86_64'
if (!(Test-Path -LiteralPath (Join-Path $sdk 'system-images/android-37.2/google_apis_ps16k/x86_64/package.xml'))) { throw 'Android 37.2 Google APIs 16k x86_64 image is not installed' }
$avd=Join-Path $env:USERPROFILE ('.android/avd/'+$Name+'.avd/config.ini')
if (!(Test-Path -LiteralPath $avd)) {
    'no' | & (Join-Path $root 'tools/jdk/bin/java.exe') ('-Dcom.android.sdkmanager.toolsdir='+$sdk+'/cmdline-tools/latest') -cp (Join-Path $sdk 'cmdline-tools/latest/lib/avdmanager-classpath.jar') com.android.sdklib.tool.AvdManagerCli create avd -n $Name -k $image --device pixel_8
    if($LASTEXITCODE -ne 0) { throw 'AVD creation failed' }
}
$existing=Get-CimInstance Win32_Process -Filter "Name LIKE 'qemu-system-x86_64%'" | Where-Object { $_.CommandLine -like ('*'+$Name+'*') }
if ($existing) { $pidValue=$existing.ProcessId } else {
    $process=Start-Process -FilePath (Join-Path $sdk 'emulator/emulator.exe') -ArgumentList @('-avd',$Name,'-no-window','-no-snapshot','-gpu','swiftshader_indirect','-ports','5554,5555','-no-audio') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root 'logs/emulator.out.log') -RedirectStandardError (Join-Path $root 'logs/emulator.err.log')
    $pidValue=$process.Id
}
Write-Output "EMULATOR_PID=$pidValue"
$adb=Join-Path $sdk 'platform-tools/adb.exe'
$wait=Start-Process -FilePath $adb -ArgumentList @('-s','emulator-5554','wait-for-device') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root 'logs/adb-wait.out.log') -RedirectStandardError (Join-Path $root 'logs/adb-wait.err.log')
$null=$wait.Handle
if(!$wait.WaitForExit($DeviceTimeoutSeconds*1000)) { Stop-Process -Id $wait.Id -Force; throw 'ADB device wait timed out' }
if($wait.ExitCode -ne 0) { throw 'ADB wait failed' }
$boot=& $adb -s emulator-5554 shell getprop sys.boot_completed
Write-Output "BOOT_COMPLETED=$boot"
& $adb -s emulator-5554 shell getprop ro.build.version.sdk
& $adb -s emulator-5554 shell getconf PAGE_SIZE
Write-Output "EMULATOR_AVD=$Name"

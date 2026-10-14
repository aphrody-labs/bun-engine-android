$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\env.ps1"
$Source = "$AndroidWorkspace\apps\java-ffi\src"
$Output = "$AndroidWorkspace\target\java-ffi"
$Library = "$AndroidWorkspace\target\rust\debug\android_native.dll"
if (!(Test-Path $Library)) { throw 'Build Rust host first: scripts/build-rust.ps1 -HostOnly' }
New-Item -ItemType Directory -Force "$Output\jni", "$Output\ffm" | Out-Null
& "$env:JAVA_HOME\bin\javac.exe" -d "$Output\jni" "$Source\main\java\com\aphrody\android\NativeBridge.java" "$Source\test\java\com\aphrody\android\FfiSmoke.java"
if ($LASTEXITCODE -ne 0) { throw 'Java JNI compilation failed' }
& "$env:JAVA_HOME\bin\java.exe" "-Djava.library.path=$AndroidWorkspace\target\rust\debug" -cp "$Output\jni" com.aphrody.android.FfiSmoke
if ($LASTEXITCODE -ne 0) { throw 'Java JNI execution failed' }
$JdkLatest = "$AndroidWorkspace\tools\jdk-latest\jdk-27+35"
& "$JdkLatest\bin\javac.exe" -d "$Output\ffm" "$Source\test\java\com\aphrody\android\ForeignSmoke.java"
if ($LASTEXITCODE -ne 0) { throw 'Java FFM compilation failed' }
& "$JdkLatest\bin\java.exe" --enable-native-access=ALL-UNNAMED -cp "$Output\ffm" com.aphrody.android.ForeignSmoke $Library
if ($LASTEXITCODE -ne 0) { throw 'Java FFM execution failed' }

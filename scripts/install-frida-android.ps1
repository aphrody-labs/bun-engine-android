$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Start-Transcript -Path (Join-Path $root 'logs/frida-android-install.log') -Append
try {
    $target = Join-Path $root 'tools/frida-android'
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    $assets = @(
        @{Arch='arm64'; Hash='f61e98db10dc1692be1cfe209e4ec32f5381759c722ab1a3f79db36730e6234e'},
        @{Arch='x86_64'; Hash='5413e802fc2edbbd7f933352542e517d8ecd55aacd5f403fe51d8170bfeaa9b6'}
    )
    foreach($asset in $assets) {
        $name = 'frida-server-17.23.3-android-' + $asset.Arch
        $file = Join-Path $root ('downloads/' + $name + '.xz')
        & curl.exe --silent --show-error --fail --location --retry 2 --connect-timeout 20 --max-time 300 --output $file ('https://github.com/frida/frida/releases/download/17.23.3/' + $name + '.xz')
        if ($LASTEXITCODE -ne 0) { throw "Download failed: $name" }
        $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $asset.Hash) { throw "Checksum mismatch: $name" }
        Write-Output "SHA256 VERIFIED $name $hash"
        & bun uv run --no-project --python 3.12 (Join-Path $PSScriptRoot 'decompress-xz.py') $file (Join-Path $target $name)
        if ($LASTEXITCODE -ne 0) { throw "Decompression failed: $name" }
    }
    foreach($repo in @(@{Name='frida'; Url='https://github.com/frida/frida.git'}, @{Name='android-skills'; Url='https://github.com/android/skills.git'})) {
        $dest = Join-Path $root ('sources/' + $repo.Name)
        if (!(Test-Path -LiteralPath (Join-Path $dest '.git'))) {
            $p=Start-Process -FilePath (Get-Command git.exe).Source -ArgumentList @('clone','--depth','1',$repo.Url,$dest) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root ('logs/clone-' + $repo.Name + '.out.log')) -RedirectStandardError (Join-Path $root ('logs/clone-' + $repo.Name + '.err.log'))
            $null=$p.Handle
            if (!$p.WaitForExit(240000)) { Stop-Process -Id $p.Id -Force; throw "Clone timeout: $($repo.Name)" }
            if($p.ExitCode -ne 0) { throw "Clone failed: $($repo.Name)" }
        }
        & git.exe -C $dest log -1 --format='%H %s'
        Write-Output "CLONED $($repo.Name)"
    }
    Write-Output 'FRIDA_ANDROID_COMPLETE'
} finally { Stop-Transcript }

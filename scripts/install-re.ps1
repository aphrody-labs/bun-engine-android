param([switch]$SourcesOnly)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$log = Join-Path $root 'logs/re-install.log'
Start-Transcript -Path $log -Append
try {
    $assets = @(
        @{Name='ghidra_12.1.4_PUBLIC_20260921.zip'; Url='https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip'; Hash='ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db'; Target='ghidra'; Strip=$true},
        @{Name='jadx-1.5.6.zip'; Url='https://github.com/skylot/jadx/releases/download/v1.5.6/jadx-1.5.6.zip'; Hash='545ea2be9c242511bc145755cf4bda2485ade42966e096f8b4d3da2a230e8974'; Target='jadx'; Strip=$false},
        @{Name='apktool_3.0.3.jar'; Url='https://github.com/iBotPeaches/Apktool/releases/download/v3.0.3/apktool_3.0.3.jar'; Hash='dbf930b076c6b9be08d57c449cacefc3bdd6b71ebd59b3066fc0e1f5b14f9423'; Target='apktool'; Strip=$false}
    )
    foreach($asset in $(if ($SourcesOnly) { @() } else { $assets })) {
        $file = Join-Path $root ('downloads/' + $asset.Name)
        if (!(Test-Path -LiteralPath $file) -or (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $asset.Hash) {
            & curl.exe --fail --location --retry 2 --connect-timeout 20 --max-time 900 --output $file $asset.Url
            if ($LASTEXITCODE -ne 0) { throw "Download failed: $($asset.Name)" }
        }
        $actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $asset.Hash) { throw "Checksum mismatch: $($asset.Name)" }
        Write-Output "SHA256 VERIFIED $($asset.Name) $actual"
        $target = Join-Path $root ('tools/' + $asset.Target)
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        if ($asset.Target -eq 'apktool') {
            Copy-Item -LiteralPath $file -Destination (Join-Path $target 'apktool.jar') -Force
        } elseif ($asset.Strip) {
            & tar.exe -xf $file -C $target --strip-components 1
            if ($LASTEXITCODE -ne 0) { throw "Extraction failed: $($asset.Name)" }
        } else {
            & tar.exe -xf $file -C $target
            if ($LASTEXITCODE -ne 0) { throw "Extraction failed: $($asset.Name)" }
        }
        Write-Output "INSTALLED $target"
    }
    $repos = @(
        @{Name='ghidra'; Url='https://github.com/NationalSecurityAgency/ghidra.git'; Tag='Ghidra_12.1.4_build'},
        @{Name='jadx'; Url='https://github.com/skylot/jadx.git'; Tag='v1.5.6'},
        @{Name='apktool'; Url='https://github.com/iBotPeaches/Apktool.git'; Tag='v3.0.3'},
        @{Name='cargo-ndk'; Url='https://github.com/bbqsrc/cargo-ndk.git'; Tag='v4.1.2'}
    )
    foreach ($repo in $repos) {
        $dest = Join-Path $root ('sources/' + $repo.Name)
        if (!(Test-Path -LiteralPath (Join-Path $dest '.git'))) {
            $args = @('clone','--depth','1')
            if ($repo.Tag) { $args += @('--branch', $repo.Tag) }
            $args += @($repo.Url, $dest)
            $p = Start-Process -FilePath (Get-Command git.exe).Source -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root ('logs/clone-' + $repo.Name + '.out.log')) -RedirectStandardError (Join-Path $root ('logs/clone-' + $repo.Name + '.err.log'))
            $null = $p.Handle
            if (!$p.WaitForExit(240000)) { Stop-Process -Id $p.Id -Force; throw "Clone timeout: $($repo.Name)" }
            if ($p.ExitCode -ne 0) { throw "Clone failed: $($repo.Name), exit $($p.ExitCode)" }
        }
        & git.exe -C $dest log -1 --format='%H %s'
        if ($LASTEXITCODE -ne 0) { throw "Git verification failed: $($repo.Name)" }
        Write-Output "CLONED $($repo.Name)"
    }
    Write-Output 'RE_INSTALL_COMPLETE'
} finally { Stop-Transcript }

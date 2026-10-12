$ErrorActionPreference = 'Stop'
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class WinCred {
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] public struct CRED { public uint Flags, Type; public IntPtr TargetName, Comment, LastWritten; public uint BlobSize; public IntPtr Blob; public uint Persist, AttributeCount; public IntPtr Attributes, TargetAlias, UserName; }
  [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern bool CredWrite(ref CRED c, uint f);
  public static void Write(string target, string user, string secret) { var b=Encoding.UTF8.GetBytes(secret); var h=GCHandle.Alloc(b,GCHandleType.Pinned); try { var c=new CRED(); c.Type=1; c.TargetName=Marshal.StringToCoTaskMemUni(target); c.UserName=Marshal.StringToCoTaskMemUni(user); c.BlobSize=(uint)b.Length; c.Blob=h.AddrOfPinnedObject(); c.Persist=2; if(!CredWrite(ref c,0)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error()); } finally { h.Free(); } }
}
'@
$files = @('C:\aphrody\.env','C:\aphrody\.env.ovh','C:\shenron\.env') | Where-Object { Test-Path -LiteralPath $_ }
$pattern = '^(?i)([A-Z][A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASSWORD|PASS|COOKIE|DATABASE_URL|REDIS_URL|POSTGRES_URL|DSN)[A-Z0-9_]*)=(.*)$'
$count=0
foreach($file in $files){
  foreach($line in [IO.File]::ReadLines($file)){
    if($line -match $pattern -and $Matches[2] -and $Matches[2] -notmatch '^(?i)(changeme|replace|example|your_)'){
      $key=$Matches[1]; $value=$Matches[2].Trim().Trim('"').Trim("'")
      if($value){ $rel=$file.Replace(':','').Replace('\','/'); $target="Aphrody/$rel/$key"; [WinCred]::Write($target,$key,$value); $count++ }
    }
  }
}
Write-Output "migrated=$count"

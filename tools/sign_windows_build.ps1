<#
.SYNOPSIS
  Code-signs the built Windows app so Smart App Control / WDAC will load it.

.DESCRIPTION
  Windows 11's Smart App Control enforces a Code Integrity policy that refuses
  to load unsigned DLLs, failing with "Bad Image ... error status 0xC0E90002".
  A Flutter release folder ships flutter_windows.dll plus one DLL per plugin,
  all unsigned, so on a machine with SAC enabled the app cannot start at all
  until every one of them carries a signature.

  This signs each .exe and .dll under -Path using signtool with SHA-256 and an
  RFC-3161 timestamp, so the signatures stay valid after the certificate
  itself expires.

  With no certificate configured the script warns and exits 0, leaving the
  build unsigned - local and CI builds keep working exactly as they do today.

  IMPORTANT: signing is necessary but may not be sufficient. Smart App Control
  trusts certificates that have established reputation; a brand-new OV
  certificate can still be blocked until it earns that. An EV code-signing
  certificate is trusted immediately.

.EXAMPLE
  .\tools\sign_windows_build.ps1 -Path build\windows\x64\runner\Release `
    -PfxPath C:\certs\aca.pfx -PfxPassword $env:CERT_PW
#>
param(
  [string] $Path = '',
  [string] $PfxPath = $env:WINDOWS_CERT_PFX,
  [string] $PfxPassword = $env:WINDOWS_CERT_PASSWORD,
  [string] $Thumbprint = $env:WINDOWS_CERT_THUMBPRINT,
  [string] $TimestampUrl = 'http://timestamp.digicert.com'
)

$ErrorActionPreference = 'Stop'

if (-not $Path) {
  $repoRoot = Split-Path $PSScriptRoot -Parent
  $Path = Join-Path $repoRoot 'build\windows\x64\runner\Release'
}

if (-not (Test-Path $Path)) {
  throw "Release folder not found: $Path (build it first with 'flutter build windows --release')"
}

if (-not $PfxPath -and -not $Thumbprint) {
  Write-Warning @'
No code-signing certificate configured - shipping UNSIGNED.

On Windows 11 machines with Smart App Control enabled this build will fail to
start with: "Bad Image ... error status 0xC0E90002" on each plugin DLL.

Set one of:
  -PfxPath / $env:WINDOWS_CERT_PFX  (+ -PfxPassword / $env:WINDOWS_CERT_PASSWORD)
  -Thumbprint / $env:WINDOWS_CERT_THUMBPRINT  (cert already in the local store)
'@
  exit 0
}

# signtool ships with the Windows SDK and is not on PATH by default.
$signtool = (Get-Command signtool.exe -ErrorAction SilentlyContinue).Source
if (-not $signtool) {
  $candidates = Get-ChildItem -Path 'C:\Program Files (x86)\Windows Kits\10\bin' `
    -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\x64\' } |
    Sort-Object FullName -Descending
  if ($candidates) { $signtool = $candidates[0].FullName }
}
if (-not $signtool) {
  throw 'signtool.exe not found. Install the Windows SDK (Signing Tools component).'
}
Write-Host "Using signtool: $signtool"

# Sign the app's own binaries. Anything already signed by a third party is
# skipped - re-signing someone else's binary would invalidate their signature.
$targets = Get-ChildItem -Path $Path -Recurse -Include *.exe, *.dll -File |
  Where-Object {
    $sig = Get-AuthenticodeSignature $_.FullName
    $sig.Status -ne 'Valid'
  }

if (-not $targets) {
  Write-Host 'Nothing to sign - every binary already carries a valid signature.'
  exit 0
}

Write-Host "Signing $($targets.Count) binaries in $Path ..."

$common = @('sign', '/fd', 'SHA256', '/tr', $TimestampUrl, '/td', 'SHA256')
if ($Thumbprint) {
  $signArgs = $common + @('/sha1', $Thumbprint)
} else {
  if (-not (Test-Path $PfxPath)) { throw "Certificate file not found: $PfxPath" }
  $signArgs = $common + @('/f', $PfxPath)
  if ($PfxPassword) { $signArgs += @('/p', $PfxPassword) }
}

$failed = @()
foreach ($file in $targets) {
  & $signtool @signArgs $file.FullName | Out-Null
  if ($LASTEXITCODE -ne 0) { $failed += $file.FullName }
}

if ($failed) {
  $failed | ForEach-Object { Write-Error "Failed to sign: $_" }
  throw "signtool failed on $($failed.Count) file(s)."
}

Write-Host "Signed $($targets.Count) binaries." -ForegroundColor Green

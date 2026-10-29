<#
.SYNOPSIS
  Publishes an AI Connect Africa GitHub release with Android + Windows
  artifacts attached.

.DESCRIPTION
  Prefer -WithModels so the Android APK is the fat build that already
  contains chat + translation models (one download link, works offline
  after install). Build those artifacts first with:

    .\tools\build_release_with_models.ps1 -Version X.Y.Z

.PARAMETER Version
  Marketing version without the leading 'v', e.g. 1.2.0

.PARAMETER ArtifactDir
  Folder holding the built artifacts (default: <repo>\dist)

.PARAMETER WithModels
  Attach AI Connect Africa vX.Y.Z-with-models.apk (recommended).
  Without this flag, looks for the slim AI Connect Africa vX.Y.Z.apk

.EXAMPLE
  .\tools\build_release_with_models.ps1 -Version 1.2.0
  .\tools\publish_release.ps1 -Version 1.2.0 -WithModels
#>

param(
  [Parameter(Mandatory = $true)] [string] $Version,
  [string] $ArtifactDir = '',
  [switch] $WithModels
)

$ErrorActionPreference = 'Stop'

$tag = "v$Version"
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $ArtifactDir) { $ArtifactDir = Join-Path $repoRoot 'dist' }

if ($WithModels) {
  $apk = Join-Path $ArtifactDir "AI Connect Africa v$Version-with-models.apk"
} else {
  $apk = Join-Path $ArtifactDir "AI Connect Africa v$Version.apk"
  if (-not (Test-Path $apk)) {
    $apk = Join-Path $ArtifactDir "AI Connect Africa v$Version-with-models.apk"
  }
}

$zip = Join-Path $ArtifactDir "AI Connect Africa Windows v$Version.zip"
$notes = Join-Path $repoRoot "dist\release-notes-v$Version.md"

foreach ($f in @($apk, $zip)) {
  if (-not (Test-Path $f)) { throw "Missing required file: $f" }
}
if (-not (Test-Path $notes)) {
  $notesDir = Split-Path $notes -Parent
  New-Item -ItemType Directory -Force $notesDir | Out-Null
  @"
## AI Connect Africa $tag

### Android (with models)
Install ``AI Connect Africa v$Version-with-models.apk`` — chat and translation
models are inside the APK. First launch unpacks them once (~1 GB free space).

### Windows
Extract ``AI Connect Africa Windows v$Version.zip`` and run
``AI Connect Africa.exe``. The ``models/`` folder next to the exe is used
automatically.
"@ | Set-Content -Encoding utf8 $notes
  Write-Host "Wrote default notes: $notes" -ForegroundColor DarkGray
}

gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "gh is not authenticated. Run this once, then re-run this script:" -ForegroundColor Yellow
  Write-Host "    gh auth login" -ForegroundColor Cyan
  throw "gh not authenticated"
}

Write-Host "Publishing $tag …" -ForegroundColor Green
$existing = gh release view $tag 2>$null
if ($LASTEXITCODE -eq 0) {
  Write-Host "Release $tag already exists — uploading assets with --clobber" -ForegroundColor Yellow
  gh release upload $tag $apk $zip --clobber
} else {
  gh release create $tag $apk $zip `
    --title "AI Connect Africa $tag" `
    --notes-file $notes
}

$repo = gh repo view --json nameWithOwner --jq .nameWithOwner
$apkName = [uri]::EscapeDataString((Split-Path $apk -Leaf))
$apkUrl = "https://github.com/$repo/releases/download/$tag/$apkName"

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Release page: https://github.com/$repo/releases/tag/$tag"
Write-Host ""
Write-Host "Direct Android download (with everything):" -ForegroundColor Cyan
Write-Host "  $apkUrl"

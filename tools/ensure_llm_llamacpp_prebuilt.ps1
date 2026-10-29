<#
.SYNOPSIS
  Seeds the llm_llamacpp prebuilt native assets cache (Windows + Android).

.DESCRIPTION
  llm_llamacpp's build hook downloads a GitHub release zip then runs `unzip`,
  which is often missing on Windows. This script downloads the same assets and
  extracts them with Expand-Archive so Flutter builds can pick up the cached
  natives without unzip or a from-source CMake build.

  Re-run after bumping llm_llamacpp (fingerprint / version change).
#>
$ErrorActionPreference = 'Stop'

$version = '0.4.0'
$abi = '3bdeb01181b8'
$cache = Join-Path $PSScriptRoot '..\.dart_tool\hooks_runner\shared\llm_llamacpp\build\.cache'
New-Item -ItemType Directory -Force -Path $cache | Out-Null

$targets = @(
  @{ Asset = "llm_llamacpp-v$version-abi$abi-windows-x64.zip"; Marker = 'llama.dll' }
  @{ Asset = "llm_llamacpp-v$version-abi$abi-android-arm64-v8a.zip"; Marker = 'libllama.so' }
  @{ Asset = "llm_llamacpp-v$version-abi$abi-android-armeabi-v7a.zip"; Marker = 'libllama.so' }
)

foreach ($t in $targets) {
  $url = "https://github.com/brynjen/dart-llm/releases/download/$version/$($t.Asset)"
  $zip = Join-Path $cache $t.Asset
  $destName = [IO.Path]::GetFileNameWithoutExtension($t.Asset) -replace "^llm_llamacpp-v$version-abi$abi-", "v$version-abi$abi-"
  # Hook dest is v0.4.0-abi3bdeb01181b8-windows-x64 (platform suffix only).
  $suffix = $t.Asset -replace "^llm_llamacpp-v$version-abi$abi-", '' -replace '\.zip$', ''
  $dest = Join-Path $cache "v$version-abi$abi-$suffix"
  $marker = Join-Path $dest $t.Marker

  if (Test-Path $marker) {
    Write-Host "Already seeded: $marker" -ForegroundColor Green
    continue
  }

  if (-not (Test-Path $zip)) {
    Write-Host "Downloading $url ..."
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
  }

  if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
  Expand-Archive -Path $zip -DestinationPath $dest -Force

  $found = Get-ChildItem $dest -Recurse -Filter $t.Marker -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $found) {
    throw "Extract succeeded but $($t.Marker) was not found under $dest"
  }
  # Hook looks for the marker at the dest root; copy up if nested.
  if (-not (Test-Path $marker)) {
    Copy-Item $found.FullName $marker -Force
    Get-ChildItem $found.Directory -File | ForEach-Object {
      Copy-Item $_.FullName (Join-Path $dest $_.Name) -Force
    }
  }
  Write-Host "Seeded $dest" -ForegroundColor Green
}

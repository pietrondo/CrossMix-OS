# CrossMix-Pit Edition - Release Builder
# Run: .\make_release.ps1
# Creates CrossMix-OS_vX.Y.Z.zip with all cores and content

param([string]$Version = "")

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$CoresDir = "$Root\RetroArch\.retroarch\cores"
$UpstreamUrl = "https://raw.githubusercontent.com/christianhaitian/retroarch-cores/master/aarch64"
$ReleaseDir = "$Root\_release"

# Auto-detect version from crossmix-version.txt
if (-not $Version) {
    $verFile = "$Root\System\usr\trimui\crossmix-version.txt"
    if (Test-Path $verFile) { $Version = (Get-Content $verFile).Trim() }
    else { Write-Error "No version specified and crossmix-version.txt not found"; exit 1 }
}
$ZipName = "CrossMix-OS_v$Version.zip"
$OutZip = "$Root\$ZipName"

Write-Host "=== CrossMix-Pit Edition Release Builder ===" -ForegroundColor Cyan
Write-Host "Version: $Version"
Write-Host ""

# Step 1: Extract .7z cores
Write-Host "[1/5] Extracting .7z cores..." -ForegroundColor Yellow
$sevenZip = Get-Command "7z.exe" -ErrorAction SilentlyContinue
if (-not $sevenZip) {
    Write-Host "  WARNING: 7z.exe not found. Download from https://www.7-zip.org/" -ForegroundColor Red
    Write-Host "  .7z cores will not be extracted."
} else {
    Get-ChildItem "$CoresDir\*.7z" | ForEach-Object {
        & 7z x $_.FullName -o"$CoresDir" -aoa -y | Out-Null
        Remove-Item $_.FullName -Force
        Write-Host "  Extracted: $($_.Name)"
    }
}

# Step 2: Download missing large cores from upstream
Write-Host "[2/5] Downloading large cores from upstream..." -ForegroundColor Yellow
$LargeCores = @(
    "fbalpha2012", "fbneo", "flycast", "flycast_rumble",
    "mame", "mame2000", "mame2003", "mame2003_plus", "mame2010", "mame2015",
    "mess", "mess2015", "puae", "same_cdi", "scummvm",
    "ppsspp", "mgba_rumble", "pcsx_rearmed_rumble",
    "genesis_plus_gx_EX", "km_fbneo_xtreme_amped"
)
$ok = 0; $nf = 0; $skip = 0
$wc = New-Object System.Net.WebClient
foreach ($core in $LargeCores) {
    $soFile = "${core}_libretro.so"
    $destSo = "$CoresDir\$soFile"
    if (Test-Path $destSo) { $skip++; continue }
    $zipUrl = "$UpstreamUrl/${soFile}.zip"
    $tmpZip = "$env:TEMP\${soFile}.zip"
    try {
        $wc.DownloadFile($zipUrl, $tmpZip)
        if ($sevenZip) {
            & 7z x $tmpZip -o"$CoresDir" -aoa -y | Out-Null
        } else {
            Expand-Archive -Path $tmpZip -DestinationPath $CoresDir -Force
        }
        Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
        $sz = [math]::Round((Get-Item $destSo).Length/1MB, 1)
        Write-Host "  OK: $soFile ($sz MB)"
        $ok++
    } catch {
        Write-Host "  NOT FOUND: $soFile"
        $nf++
        Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "  Downloaded: $ok, Not found: $nf, Already present: $skip"

# Step 3: Clean up dev files
Write-Host "[3/5] Cleaning dev files..." -ForegroundColor Yellow
$ReleaseDir = "$Root\_release"
if (Test-Path $ReleaseDir) { Remove-Item -Recurse -Force $ReleaseDir }
New-Item -ItemType Directory -Path $ReleaseDir | Out-Null

Copy-Item -Recurse "$Root\*" $ReleaseDir -Exclude "_release", "_assets", ".git", ".github", ".beads", ".serena", "graphify-out", "make_release.ps1", "*.zip", "*.md"
Get-ChildItem $ReleaseDir -Recurse -Filter ".gitkeep" | Remove-Item -Force

# Step 4: Create zip
Write-Host "[4/5] Creating $ZipName..." -ForegroundColor Yellow
if (Test-Path $OutZip) { Remove-Item $OutZip -Force }
Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $OutZip -CompressionLevel Optimal
Write-Host "  Size: $([math]::Round((Get-Item $OutZip).Length/1MB,0)) MB"

# Step 5: Generate SHA256
Write-Host "[5/5] Generating SHA256..." -ForegroundColor Yellow
$sha256 = (Get-FileHash -Algorithm SHA256 -Path $OutZip).Hash.ToLower()
"$sha256  $ZipName" | Out-File "$OutZip.sha256" -Encoding ascii
Write-Host "  SHA256: $sha256"

# Cleanup
Remove-Item -Recurse -Force $ReleaseDir

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "  Zip: $OutZip"
Write-Host "  SHA256: $OutZip.sha256"
Write-Host ""
Write-Host "To update your device:"
Write-Host "  1. Copy $ZipName to the root of your SD card"
Write-Host "  2. On the TrimUI, open Apps -> Updates and press A"

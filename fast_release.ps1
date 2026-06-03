$Root = $PSScriptRoot
$ReleaseDir = "$Root\_release"
$Version = "1.7.1-pit"
$ZipName = "CrossMix-OS_v$Version.zip"
$OutZip = "$Root\$ZipName"

Remove-Item -Force $OutZip -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $ReleaseDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory $ReleaseDir | Out-Null

Write-Host "Copying files..." -ForegroundColor Yellow
robocopy $Root $ReleaseDir /E /XD _release _assets .git .github .beads .serena graphify-out /XF *.zip make_release.ps1 build_release.ps1 fast_release.ps1 /NFL /NDL /NJH /NJS | Out-Null

Get-ChildItem $ReleaseDir -Recurse -Filter ".gitkeep" | Remove-Item -Force
Get-ChildItem $ReleaseDir -Recurse -Filter "*.md" | Remove-Item -Force
Get-ChildItem $ReleaseDir -Recurse -Filter ".gitignore" | Remove-Item -Force

# Exclude .so core files (too large, downloaded on-device instead)
Remove-Item -Recurse -Force "$ReleaseDir\RetroArch\.retroarch\cores\*.so" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$ReleaseDir\RetroArch\.retroarch\cores\*.7z" -ErrorAction SilentlyContinue

# Exclude heavy RetroArch theme assets (keep ozone only)
if (Test-Path "$ReleaseDir\RetroArch\.retroarch\assets") {
    Remove-Item -Recurse -Force "$ReleaseDir\RetroArch\.retroarch\assets\xmb" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$ReleaseDir\RetroArch\.retroarch\assets\switch" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "$ReleaseDir\RetroArch\.retroarch\assets\glui" -ErrorAction SilentlyContinue
}

# Exclude PortMaster themes (huge, non-critical)
Remove-Item -Recurse -Force "$ReleaseDir\Apps\PortMaster\PortMaster\themes" -ErrorAction SilentlyContinue

# Exclude old ScummVM extras
Remove-Item -Force "$ReleaseDir\Emus\SCUMMVM\ScummVM\scummvm.7z" -ErrorAction SilentlyContinue

# Exclude non-essential apps and assets
Remove-Item -Recurse -Force "$ReleaseDir\Apps\EbookReader" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$ReleaseDir\Apps\BootLogo\Images_1024x768" -ErrorAction SilentlyContinue

# Keep only CrossMix + Stock boot logos (remove all others to save space)
if (Test-Path "$ReleaseDir\Apps\BootLogo\Images_1280x720") {
    Get-ChildItem "$ReleaseDir\Apps\BootLogo\Images_1280x720" -File | Where-Object {
        $_.Name -notlike "*Crossmix*" -and $_.Name -notlike "*CrossMix*" -and $_.Name -notlike "*Default Trimui*" -and $_.Name -notlike "*Pit*"
    } | Remove-Item -Force
}

# Keep only essential themes (CrossMix + TRIMUI Blue + Epic Noir + Burst!)
if (Test-Path "$ReleaseDir\Themes") {
    Get-ChildItem "$ReleaseDir\Themes" -Directory | Where-Object {
        $_.Name -notlike "CrossMix*" -and $_.Name -notlike "TRIMUI Blue" -and $_.Name -notlike "Epic Noir" -and $_.Name -notlike "Burst!"
    } | Remove-Item -Recurse -Force
}

# Keep only Default + Burst! icon packs
if (Test-Path "$ReleaseDir\Icons") {
    Get-ChildItem "$ReleaseDir\Icons" -Directory | Where-Object {
        $_.Name -notlike "Default" -and $_.Name -notlike "Burst!"
    } | Remove-Item -Recurse -Force
}

# Keep only Default + Burst! backgrounds
if (Test-Path "$ReleaseDir\Backgrounds") {
    Get-ChildItem "$ReleaseDir\Backgrounds" -Directory | Where-Object {
        $_.Name -notlike "Default" -and $_.Name -notlike "Burst!"
    } | Remove-Item -Recurse -Force
}

# PortMaster: keep only launch script, remove heavy assets
Remove-Item -Recurse -Force "$ReleaseDir\Apps\PortMaster\PortMaster" -ErrorAction SilentlyContinue

Write-Host "Compressing..." -ForegroundColor Yellow
Compress-Archive -Path "$ReleaseDir\*" -DestinationPath $OutZip -CompressionLevel Fastest
$size = [math]::Round((Get-Item $OutZip).Length / 1MB, 0)
Write-Host "  Size: $size MB"

Remove-Item -Recurse -Force $ReleaseDir

Write-Host "Generating SHA256..." -ForegroundColor Yellow
$sha256 = (Get-FileHash -Algorithm SHA256 -Path $OutZip).Hash.ToLower()
"$sha256  $ZipName" | Out-File "$OutZip.sha256" -Encoding ascii
Write-Host "  SHA256: $sha256"

Write-Host ""
Write-Host "=== DONE ===" -ForegroundColor Green
Write-Host "  Zip: $OutZip"
Write-Host "  SHA256: $OutZip.sha256"

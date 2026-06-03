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

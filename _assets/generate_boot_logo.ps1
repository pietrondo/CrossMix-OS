# Cross-Pit Boot Logo Generator
# Creates a BMP boot logo for TrimUI Smart Pro (1280x720)
# Requires: System.Drawing (Windows)

Add-Type -AssemblyName System.Drawing

$outPath = "Apps\BootLogo\Images_1280x720\Crossmix Pit.bmp"
$bmp = New-Object System.Drawing.Bitmap(1280, 720)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'HighQuality'
$g.TextRenderingHint = 'AntiAlias'

# Background
$bg = [System.Drawing.Color]::FromArgb(10, 10, 21)
$g.Clear($bg)

# Grid lines (subtle tech feel)
$gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(15, 0, 180, 216), 1)
$g.DrawLine($gridPen, 0, 360, 1280, 360)
$g.DrawLine($gridPen, 640, 0, 640, 720)

# Diamond icon (center)
$diamondPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 0, 180, 216), 3)
$diamondBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(13, 13, 32))
$diamondPoints = [System.Drawing.Point[]]@(
    (New-Object System.Drawing.Point(640, 220)),
    (New-Object System.Drawing.Point(710, 290)),
    (New-Object System.Drawing.Point(640, 360)),
    (New-Object System.Drawing.Point(570, 290))
)
$g.FillPolygon($diamondBrush, $diamondPoints)
$g.DrawPolygon($diamondPen, $diamondPoints)

# Cross inside diamond
$crossPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 180, 216), 5)
$crossPen.StartCap = 'Round'
$crossPen.EndCap = 'Round'
$g.DrawLine($crossPen, 618, 290, 662, 290)
$g.DrawLine($crossPen, 640, 268, 640, 312)

# Glow ring around diamond
$ringPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 0, 180, 216), 1)
$g.DrawEllipse($ringPen, 550, 200, 180, 180)

# Fire embers (orange dots)
$emberColors = @(
    [System.Drawing.Color]::FromArgb(150, 255, 140, 0),
    [System.Drawing.Color]::FromArgb(120, 255, 208, 0),
    [System.Drawing.Color]::FromArgb(100, 255, 107, 0)
)
$embers = @(
    @{X=590; Y=380; S=3}, @{X=620; Y=370; S=2}, @{X=660; Y=375; S=4},
    @{X=680; Y=365; S=2}, @{X=610; Y=395; S=3}, @{X=650; Y=398; S=2},
    @{X=700; Y=380; S=2}, @{X=570; Y=388; S=2}, @{X=695; Y=400; S=3},
    @{X=640; Y=405; S=2}
)
foreach ($em in $embers) {
    $c = $emberColors | Get-Random
    $eb = New-Object System.Drawing.SolidBrush($c)
    $g.FillEllipse($eb, $em.X - $em.S/2, $em.Y - $em.S/2, $em.S, $em.S)
    $eb.Dispose()
}

# Fire glow at bottom of diamond
$glowBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Point(640, 380)),
    (New-Object System.Drawing.Point(640, 420)),
    [System.Drawing.Color]::FromArgb(50, 255, 107, 0),
    [System.Drawing.Color]::Transparent
)
$g.FillEllipse($glowBrush, 560, 370, 160, 30)
$glowBrush.Dispose()

# CROSSMIX text
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = 'Center'
$sf.LineAlignment = 'Center'

$cyanBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF(640, 500)),
    (New-Object System.Drawing.PointF(640, 560)),
    [System.Drawing.Color]::FromArgb(255, 72, 202, 228),
    [System.Drawing.Color]::FromArgb(255, 0, 180, 216)
)

$font64 = New-Object System.Drawing.Font('Segoe UI', 64, [System.Drawing.FontStyle]::Bold)
$g.DrawString('CROSSMIX', $font64, $cyanBrush, (New-Object System.Drawing.RectangleF(0, 485, 1280, 80)), $sf)
$cyanBrush.Dispose()

# PIT text
$orangeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 255, 140, 0))
$font32 = New-Object System.Drawing.Font('Segoe UI', 36, [System.Drawing.FontStyle]::Bold)
$g.DrawString('PIT', $font32, $orangeBrush, (New-Object System.Drawing.RectangleF(0, 555, 1280, 50)), $sf)
$orangeBrush.Dispose()

# EDITION text
$grayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(100, 0, 180, 216))
$font12 = New-Object System.Drawing.Font('Segoe UI', 14)
$g.DrawString('EDITION', $font12, $grayBrush, (New-Object System.Drawing.RectangleF(0, 600, 1280, 30)), $sf)
$grayBrush.Dispose()

# Save
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Bmp)

# Cleanup
$g.Dispose()
$bmp.Dispose()
$font64.Dispose()
$font32.Dispose()
$font12.Dispose()
$sf.Dispose()
$gridPen.Dispose()
$diamondPen.Dispose()
$diamondBrush.Dispose()
$crossPen.Dispose()
$ringPen.Dispose()

$info = Get-Item $outPath
Write-Output "Created: $($info.FullName)"
Write-Output "Size: $([math]::Round($info.Length / 1MB, 2)) MB"
Write-Output "Resolution: 1280x720 BMP"

Add-Type -AssemblyName System.Drawing

$sourcePath = "c:\Users\ASUS\.gemini\antigravity\scratch\core-vission\core_vision\assets\images\savora_logo_clean.png"
$baseDir = "c:\Users\ASUS\.gemini\antigravity\scratch\core-vission\core_vision\android\app\src\main\res"

$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

if (-not (Test-Path $sourcePath)) {
    Write-Host "Source file not found!"
    exit
}

$image = [System.Drawing.Image]::FromFile($sourcePath)

foreach ($key in $sizes.Keys) {
    $size = $sizes[$key]
    $targetDir = Join-Path $baseDir $key
    
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    
    $targetPath = Join-Path $targetDir "ic_launcher.png"
    
    $bitmap = New-Object System.Drawing.Bitmap $size, $size
    $graph = [System.Drawing.Graphics]::FromImage($bitmap)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graph.DrawImage($image, 0, 0, $size, $size)
    $bitmap.Save($targetPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graph.Dispose()
    $bitmap.Dispose()
    
    Write-Host "Generated $key ($size x $size)"
}

$image.Dispose()
Write-Host "Done."

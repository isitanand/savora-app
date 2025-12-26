
Add-Type -AssemblyName System.Drawing

$inputPath = "$PSScriptRoot\assets\images\savora_logo.png"
$outputPath = "$PSScriptRoot\assets\images\savora_logo_clean.png"

# Zoom Factor 1.55 (to be safe)
$zoomFactor = 1.55

try {
    $img = [System.Drawing.Bitmap]::FromFile($inputPath)
    $width = $img.Width
    $height = $img.Height

    $viewWidth = [int]($width / $zoomFactor)
    $viewHeight = [int]($height / $zoomFactor)

    $startX = [int](($width - $viewWidth) / 2)
    $startY = [int](($height - $viewHeight) / 2)

    $rect = New-Object System.Drawing.Rectangle $startX, $startY, $viewWidth, $viewHeight
    
    # Clone the cropped area
    $croppedImg = $img.Clone($rect, $img.PixelFormat)

    # Optional: Resize back to original (Lanczos not easily available in raw GDI+, but default resize is okay for icon)
    # Actually, let's just save the cropped version. High res enough usually.
    # But for icon generation quality, let's resize back to original 1024x1024 or whatever it is.
    
    $resizedImg = New-Object System.Drawing.Bitmap $width, $height
    $graph = [System.Drawing.Graphics]::FromImage($resizedImg)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graph.DrawImage($croppedImg, 0, 0, $width, $height)
    
    $resizedImg.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    $img.Dispose()
    $croppedImg.Dispose()
    $resizedImg.Dispose()
    $graph.Dispose()
    
    Write-Host "Success: Cropped image saved to $outputPath"
}
catch {
    Write-Host "Error: $_"
    exit 1
}

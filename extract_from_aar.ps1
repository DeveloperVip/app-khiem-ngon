# Script để extract native libraries từ AAR file đã download
# Chạy: .\extract_from_aar.ps1

$jniLibsPath = "android\app\src\main\jniLibs"

Write-Host "Extracting native libraries from AAR files..." -ForegroundColor Cyan
Write-Host ""

# Tạo thư mục đích
New-Item -ItemType Directory -Force -Path "$jniLibsPath\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\armeabi-v7a" | Out-Null

# Tìm tất cả AAR files
$aarFiles = Get-ChildItem -Path $jniLibsPath -Filter "*.aar"

if ($aarFiles.Count -eq 0) {
    Write-Host "No AAR files found in $jniLibsPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please download AAR files first:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/2.14.0/"
    Write-Host "2. Download: tensorflow-lite-2.14.0.aar"
    Write-Host "3. Place in: $jniLibsPath"
    exit 1
}

foreach ($aar in $aarFiles) {
    Write-Host "Processing: $($aar.Name)" -ForegroundColor Yellow
    
    $zipFile = $aar.FullName.Replace(".aar", ".zip")
    $extractPath = Join-Path $jniLibsPath "temp-extract-$($aar.BaseName)"
    
    try {
        # Copy và rename thành .zip
        Copy-Item $aar.FullName $zipFile -Force
        
        # Extract
        Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
        
        # Tìm .so files trong jni folder
        $jniPath = Join-Path $extractPath "jni"
        if (Test-Path $jniPath) {
            $soFiles = Get-ChildItem -Recurse $jniPath -Filter "libtensorflowlite_c.so"
            
            foreach ($so in $soFiles) {
                $fullPath = $so.FullName
                $relativePath = $fullPath.Replace($jniPath + "\", "")
                
                # Xác định architecture
                if ($relativePath -like "*arm64-v8a*" -or $relativePath -like "*arm64*") {
                    $dest = Join-Path "$jniLibsPath\arm64-v8a" "libtensorflowlite_c.so"
                    Copy-Item $fullPath -Destination $dest -Force
                    Write-Host "  -> Copied to arm64-v8a" -ForegroundColor Green
                }
                if ($relativePath -like "*armeabi-v7a*" -or $relativePath -like "*armeabi*") {
                    $dest = Join-Path "$jniLibsPath\armeabi-v7a" "libtensorflowlite_c.so"
                    Copy-Item $fullPath -Destination $dest -Force
                    Write-Host "  -> Copied to armeabi-v7a" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "  Warning: No 'jni' folder found in AAR" -ForegroundColor Yellow
        }
        
        # Cleanup
        Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
        Remove-Item $zipFile -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Kiểm tra kết quả
Write-Host ""
Write-Host "Result:" -ForegroundColor Cyan
$finalFiles = Get-ChildItem -Recurse $jniLibsPath -Filter "*.so" | Where-Object { $_.DirectoryName -notlike "*temp*" }

if ($finalFiles.Count -gt 0) {
    Write-Host "Success! Found $($finalFiles.Count) library file(s):" -ForegroundColor Green
    $finalFiles | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 2)
        Write-Host "  $($_.FullName) ($size KB)" -ForegroundColor Cyan
    }
} else {
    Write-Host "No libraries extracted. Trying alternative method..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternative: Download directly from GitHub:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/tensorflow/tensorflow/releases"
    Write-Host "2. Find TensorFlow Lite 2.14.0 release"
    Write-Host "3. Download libtensorflowlite_c.so for arm64-v8a and armeabi-v7a"
    Write-Host "4. Copy to: $jniLibsPath\arm64-v8a\ and $jniLibsPath\armeabi-v7a\"
}










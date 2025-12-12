# Script để download TensorFlow Lite native libraries
# Chạy: .\download_tflite_native_libs.ps1

$TFLITE_VERSION = "2.14.0"
$BASE_URL = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$TFLITE_VERSION"

$ARCHS = @(
    @{ name = "armeabi-v7a"; path = "android\app\src\main\jniLibs\armeabi-v7a" },
    @{ name = "arm64-v8a"; path = "android\app\src\main\jniLibs\arm64-v8a" },
    @{ name = "x86"; path = "android\app\src\main\jniLibs\x86" },
    @{ name = "x86_64"; path = "android\app\src\main\jniLibs\x86_64" }
)

Write-Host "📥 Đang download TensorFlow Lite native libraries (version $TFLITE_VERSION)..." -ForegroundColor Cyan

foreach ($arch in $ARCHS) {
    $libName = "libtensorflowlite_c.so"
    $url = "$BASE_URL/tensorflow-lite-$TFLITE_VERSION-$($arch.name).aar"
    $outputPath = "$($arch.path)\$libName"
    
    Write-Host "`n📦 Architecture: $($arch.name)" -ForegroundColor Yellow
    
    # Tạo thư mục nếu chưa có
    New-Item -ItemType Directory -Force -Path $arch.path | Out-Null
    
    # Download AAR file
    $aarFile = "$($arch.path)\tensorflow-lite-$TFLITE_VERSION-$($arch.name).aar"
    Write-Host "   Downloading: $url"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $aarFile -ErrorAction Stop
        Write-Host "   ✅ Downloaded AAR file" -ForegroundColor Green
        
        # Extract .so file từ AAR (AAR là ZIP file)
        Write-Host "   Extracting $libName from AAR..."
        Expand-Archive -Path $aarFile -DestinationPath "$($arch.path)\temp" -Force
        
        # Tìm file .so trong AAR
        $soFile = Get-ChildItem -Recurse "$($arch.path)\temp" -Filter "libtensorflowlite_c.so" | Select-Object -First 1
        
        if ($soFile) {
            Copy-Item $soFile.FullName -Destination $outputPath -Force
            Write-Host "   ✅ Copied $libName to $outputPath" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ Không tìm thấy $libName trong AAR" -ForegroundColor Yellow
        }
        
        # Cleanup
        Remove-Item -Recurse -Force "$($arch.path)\temp" -ErrorAction SilentlyContinue
        Remove-Item $aarFile -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "   ❌ Lỗi: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   💡 Thử download thủ công từ: $url" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Hoàn thành! Kiểm tra các file .so trong android\app\src\main\jniLibs\" -ForegroundColor Green









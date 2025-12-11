# Script đơn giản để download TensorFlow Lite native libraries
# Chạy: .\download_native_libs.ps1

$TFLITE_VERSION = "2.14.0"
$BASE_URL = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$TFLITE_VERSION"

Write-Host "📥 Downloading TensorFlow Lite native libraries (v$TFLITE_VERSION)..." -ForegroundColor Cyan

# Tạo thư mục jniLibs
$jniLibsPath = "android\app\src\main\jniLibs"
New-Item -ItemType Directory -Force -Path "$jniLibsPath\armeabi-v7a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\x86" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\x86_64" | Out-Null

# Download cho arm64-v8a (phổ biến nhất)
Write-Host "`n📦 Downloading arm64-v8a..." -ForegroundColor Yellow
try {
    $aarFile = "$jniLibsPath\temp-arm64.aar"
    Invoke-WebRequest -Uri "$BASE_URL/tensorflow-lite-$TFLITE_VERSION-arm64-v8a.aar" -OutFile $aarFile
    Expand-Archive -Path $aarFile -DestinationPath "$jniLibsPath\temp-arm64" -Force
    $soFile = Get-ChildItem -Recurse "$jniLibsPath\temp-arm64" -Filter "libtensorflowlite_c.so" | Select-Object -First 1
    if ($soFile) {
        Copy-Item $soFile.FullName -Destination "$jniLibsPath\arm64-v8a\libtensorflowlite_c.so" -Force
        Write-Host "   ✅ arm64-v8a: OK" -ForegroundColor Green
    }
    Remove-Item -Recurse -Force "$jniLibsPath\temp-arm64", $aarFile -ErrorAction SilentlyContinue
} catch {
    Write-Host "   ❌ arm64-v8a: $($_.Exception.Message)" -ForegroundColor Red
}

# Download cho armeabi-v7a
Write-Host "`n📦 Downloading armeabi-v7a..." -ForegroundColor Yellow
try {
    $aarFile = "$jniLibsPath\temp-armv7.aar"
    Invoke-WebRequest -Uri "$BASE_URL/tensorflow-lite-$TFLITE_VERSION-armeabi-v7a.aar" -OutFile $aarFile
    Expand-Archive -Path $aarFile -DestinationPath "$jniLibsPath\temp-armv7" -Force
    $soFile = Get-ChildItem -Recurse "$jniLibsPath\temp-armv7" -Filter "libtensorflowlite_c.so" | Select-Object -First 1
    if ($soFile) {
        Copy-Item $soFile.FullName -Destination "$jniLibsPath\armeabi-v7a\libtensorflowlite_c.so" -Force
        Write-Host "   ✅ armeabi-v7a: OK" -ForegroundColor Green
    }
    Remove-Item -Recurse -Force "$jniLibsPath\temp-armv7", $aarFile -ErrorAction SilentlyContinue
} catch {
    Write-Host "   ❌ armeabi-v7a: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n✅ Hoàn thành! Kiểm tra:" -ForegroundColor Green
$soFiles = Get-ChildItem -Recurse $jniLibsPath -Filter "*.so"
if ($soFiles) {
    $soFiles | ForEach-Object {
        Write-Host "   $($_.FullName)" -ForegroundColor Cyan
    }
} else {
    Write-Host "   ⚠️ Không tìm thấy file .so nào!" -ForegroundColor Yellow
}


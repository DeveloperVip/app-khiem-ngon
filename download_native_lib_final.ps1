# Script cuối cùng để download native libraries
# Chạy: .\download_native_lib_final.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔧 Downloading TensorFlow Lite Native Libraries..." -ForegroundColor Cyan
Write-Host ""

$jniLibsPath = "android\app\src\main\jniLibs"
$version = "2.14.0"

# Tạo thư mục
Write-Host "📁 Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$jniLibsPath\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\armeabi-v7a" | Out-Null
Write-Host "✅ Directories created" -ForegroundColor Green
Write-Host ""

# URL từ Maven Central - AAR chứa native libraries
$baseUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version"
$aarFile = "$jniLibsPath\temp-tflite.aar"
$extractPath = "$jniLibsPath\temp-extract"

try {
    Write-Host "📥 Downloading TensorFlow Lite AAR..." -ForegroundColor Yellow
    $aarUrl = "$baseUrl/tensorflow-lite-$version.aar"
    Write-Host "   URL: $aarUrl"
    
    Invoke-WebRequest -Uri $aarUrl -OutFile $aarFile -ErrorAction Stop
    $fileSize = [math]::Round((Get-Item $aarFile).Length / 1MB, 2)
    Write-Host "✅ Downloaded AAR ($fileSize MB)" -ForegroundColor Green
    Write-Host ""
    
    # Extract AAR (AAR là ZIP file)
    Write-Host "📦 Extracting AAR..." -ForegroundColor Yellow
    Expand-Archive -Path $aarFile -DestinationPath $extractPath -Force
    Write-Host "✅ Extracted" -ForegroundColor Green
    Write-Host ""
    
    # Tìm .so files trong jni folder
    Write-Host "🔍 Searching for native libraries..." -ForegroundColor Yellow
    $jniPath = Join-Path $extractPath "jni"
    
    if (Test-Path $jniPath) {
        $soFiles = Get-ChildItem -Recurse $jniPath -Filter "libtensorflowlite_c.so"
        
        if ($soFiles.Count -gt 0) {
            Write-Host "✅ Found $($soFiles.Count) native library file(s)" -ForegroundColor Green
            Write-Host ""
            
            foreach ($so in $soFiles) {
                $fullPath = $so.FullName
                $relativePath = $fullPath.Replace($jniPath + "\", "")
                
                # Xác định architecture từ đường dẫn
                $arch = $null
                if ($relativePath -like "*arm64-v8a*" -or $relativePath -like "*arm64*") {
                    $arch = "arm64-v8a"
                } elseif ($relativePath -like "*armeabi-v7a*" -or $relativePath -like "*armeabi*") {
                    $arch = "armeabi-v7a"
                } elseif ($relativePath -like "*x86_64*") {
                    $arch = "x86_64"
                } elseif ($relativePath -like "*x86*") {
                    $arch = "x86"
                }
                
                if ($arch -and ($arch -eq "arm64-v8a" -or $arch -eq "armeabi-v7a")) {
                    $destPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_c.so"
                    Copy-Item $fullPath -Destination $destPath -Force
                    Write-Host "   ✅ Copied to $arch" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "⚠️ No .so files found in jni folder" -ForegroundColor Yellow
            Write-Host "   Checking root of AAR..." -ForegroundColor Yellow
            
            # Thử tìm trong root của AAR
            $soFiles = Get-ChildItem -Recurse $extractPath -Filter "*.so" | Where-Object { $_.FullName -notlike "*temp*" }
            if ($soFiles) {
                Write-Host "   Found $($soFiles.Count) .so file(s) in root" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "❌ No 'jni' folder found in AAR" -ForegroundColor Red
    }
    
    # Cleanup
    Write-Host ""
    Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
    Remove-Item $aarFile -ErrorAction SilentlyContinue
    Write-Host "✅ Cleanup done" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Please download manually:" -ForegroundColor Yellow
    Write-Host "   1. Go to: https://github.com/tensorflow/tensorflow/releases"
    Write-Host "   2. Find TensorFlow Lite $version release"
    Write-Host "   3. Download libtensorflowlite_c.so for arm64-v8a and armeabi-v7a"
    Write-Host "   4. Copy to: $jniLibsPath\arm64-v8a\ and $jniLibsPath\armeabi-v7a\"
    exit 1
}

# Kiểm tra kết quả
Write-Host ""
Write-Host "📋 Final check:" -ForegroundColor Cyan
$finalFiles = Get-ChildItem -Recurse $jniLibsPath -Filter "*.so" | Where-Object { $_.DirectoryName -notlike "*temp*" }

if ($finalFiles.Count -gt 0) {
    Write-Host "✅ Native libraries ready:" -ForegroundColor Green
    $finalFiles | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 2)
        Write-Host "   $($_.FullName) ($size KB)" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "✅ Setup complete! Now rebuild APK:" -ForegroundColor Green
    Write-Host "   flutter clean" -ForegroundColor Yellow
    Write-Host "   flutter build apk --release" -ForegroundColor Yellow
} else {
    Write-Host "❌ No native libraries found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually and place in:" -ForegroundColor Yellow
    Write-Host "   $jniLibsPath\arm64-v8a\libtensorflowlite_c.so"
    Write-Host "   $jniLibsPath\armeabi-v7a\libtensorflowlite_c.so"
    exit 1
}


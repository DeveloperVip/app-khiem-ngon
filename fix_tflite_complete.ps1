# Script hoàn chỉnh để fix TensorFlow Lite native libraries
# Chạy: .\fix_tflite_complete.ps1

$ErrorActionPreference = "Stop"

Write-Host "🔧 Fix TensorFlow Lite Native Libraries - Giải Pháp Triệt Để" -ForegroundColor Cyan
Write-Host ""

$projectRoot = "C:\Users\hoang\Project\PTIT\Flutter\flutter_application_initial"
$jniLibsPath = "$projectRoot\android\app\src\main\jniLibs"
$version = "2.14.0"

# Bước 1: Tạo thư mục
Write-Host "📁 Bước 1: Tạo thư mục jniLibs..." -ForegroundColor Yellow
$archs = @("arm64-v8a", "armeabi-v7a", "x86", "x86_64")
foreach ($arch in $archs) {
    $archPath = Join-Path $jniLibsPath $arch
    New-Item -ItemType Directory -Force -Path $archPath | Out-Null
}
Write-Host "✅ Đã tạo thư mục" -ForegroundColor Green
Write-Host ""

# Bước 2: Tìm trong Gradle cache
Write-Host "🔍 Bước 2: Tìm libraries trong Gradle cache..." -ForegroundColor Yellow
$gradleCache = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\org.tensorflow\tensorflow-lite"
$foundInCache = $false

if (Test-Path $gradleCache) {
    Write-Host "✅ Tìm thấy Gradle cache" -ForegroundColor Green
    $soFiles = Get-ChildItem -Recurse $gradleCache -Filter "*.so" -ErrorAction SilentlyContinue
    
    if ($soFiles) {
        Write-Host "✅ Tìm thấy $($soFiles.Count) file .so" -ForegroundColor Green
        Write-Host ""
        
        foreach ($so in $soFiles) {
            $parentDir = $so.Directory.Name
            $arch = $null
            
            if ($parentDir -like "*arm64*") {
                $arch = "arm64-v8a"
            } elseif ($parentDir -like "*armeabi*") {
                $arch = "armeabi-v7a"
            } elseif ($parentDir -like "*x86_64*") {
                $arch = "x86_64"
            } elseif ($parentDir -like "*x86*") {
                $arch = "x86"
            }
            
            if ($arch -and $so.Name -like "*tensorflowlite*") {
                $destPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_c.so"
                Copy-Item $so.FullName -Destination $destPath -Force
                Write-Host "  ✅ Copied to $arch\libtensorflowlite_c.so" -ForegroundColor Green
                $foundInCache = $true
                
                if ($so.Name -like "*jni*") {
                    $jniDestPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_jni.so"
                    Copy-Item $so.FullName -Destination $jniDestPath -Force
                    Write-Host "  ✅ Also copied as libtensorflowlite_jni.so" -ForegroundColor Green
                }
            }
        }
    }
}

# Bước 3: Nếu không tìm thấy, download từ Maven
if (-not $foundInCache) {
    Write-Host "⚠️ Không tìm thấy trong cache" -ForegroundColor Yellow
    Write-Host "📥 Bước 3: Download từ Maven..." -ForegroundColor Yellow
    
    $aarFile = "$jniLibsPath\temp-tflite.aar"
    $extractPath = "$jniLibsPath\temp-extract"
    
    try {
        $aarUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version/tensorflow-lite-$version.aar"
        Write-Host "   Downloading: $aarUrl"
        Invoke-WebRequest -Uri $aarUrl -OutFile $aarFile -ErrorAction Stop
        
        Write-Host "📦 Extracting AAR..." -ForegroundColor Yellow
        Expand-Archive -Path $aarFile -DestinationPath $extractPath -Force
        
        $jniPath = Join-Path $extractPath "jni"
        if (Test-Path $jniPath) {
            $soFiles = Get-ChildItem -Recurse $jniPath -Filter "*.so"
            
            foreach ($so in $soFiles) {
                $relativePath = $so.FullName.Replace($jniPath + "\", "")
                $arch = $null
                
                if ($relativePath -like "*arm64*") {
                    $arch = "arm64-v8a"
                } elseif ($relativePath -like "*armeabi*") {
                    $arch = "armeabi-v7a"
                } elseif ($relativePath -like "*x86_64*") {
                    $arch = "x86_64"
                } elseif ($relativePath -like "*x86*") {
                    $arch = "x86"
                }
                
                if ($arch -and $so.Name -like "*tensorflowlite*") {
                    $destPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_c.so"
                    Copy-Item $so.FullName -Destination $destPath -Force
                    Write-Host "  ✅ Copied to $arch\libtensorflowlite_c.so" -ForegroundColor Green
                    
                    if ($so.Name -like "*jni*") {
                        $jniDestPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_jni.so"
                        Copy-Item $so.FullName -Destination $jniDestPath -Force
                        Write-Host "  ✅ Also copied as libtensorflowlite_jni.so" -ForegroundColor Green
                    }
                }
            }
        }
        
        Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
        Remove-Item $aarFile -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "❌ Lỗi download: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Bước 4: Kiểm tra kết quả
Write-Host ""
Write-Host "📋 Bước 4: Kiểm tra kết quả..." -ForegroundColor Cyan
$allGood = $true
foreach ($arch in $archs) {
    $archPath = Join-Path $jniLibsPath $arch
    $soFile = Join-Path $archPath "libtensorflowlite_c.so"
    
    if (Test-Path $soFile) {
        $size = [math]::Round((Get-Item $soFile).Length / 1KB, 2)
        Write-Host "  ✅ $arch\libtensorflowlite_c.so ($size KB)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $arch\libtensorflowlite_c.so - KHÔNG TỒN TẠI" -ForegroundColor Red
        $allGood = $false
    }
}

if ($allGood) {
    Write-Host ""
    Write-Host "✅ HOÀN TẤT! Tất cả libraries đã sẵn sàng" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Bước tiếp theo:" -ForegroundColor Yellow
    Write-Host "   1. cd android" -ForegroundColor White
    Write-Host "   2. .\gradlew extractTfliteNativeLibs" -ForegroundColor White
    Write-Host "   3. cd .." -ForegroundColor White
    Write-Host "   4. flutter clean" -ForegroundColor White
    Write-Host "   5. flutter build apk --release" -ForegroundColor White
    Write-Host ""
    Write-Host "Hoặc chạy app:" -ForegroundColor Yellow
    Write-Host "   flutter run --release" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Vẫn còn thiếu libraries!" -ForegroundColor Red
    Write-Host "   Vui lòng download thủ công từ:" -ForegroundColor Yellow
    $mavenUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version/"
    Write-Host "   $mavenUrl"
}


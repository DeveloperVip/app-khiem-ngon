# Script để fix TensorFlow Lite native libraries
# Extract từ Gradle cache và đảm bảo được copy vào APK

$ErrorActionPreference = "Stop"

Write-Host "🔧 Fixing TensorFlow Lite Native Libraries..." -ForegroundColor Cyan
Write-Host ""

$jniLibsPath = "android\app\src\main\jniLibs"
$version = "2.14.0"

# Tạo thư mục
Write-Host "📁 Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$jniLibsPath\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\armeabi-v7a" | Out-Null
Write-Host "✅ Directories created" -ForegroundColor Green
Write-Host ""

# Tìm trong Gradle cache
Write-Host "🔍 Searching Gradle cache..." -ForegroundColor Yellow
$gradleCache = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\org.tensorflow\tensorflow-lite"
$foundLibs = $false

if (Test-Path $gradleCache) {
    Write-Host "✅ Found Gradle cache: $gradleCache" -ForegroundColor Green
    
    # Tìm tất cả .so files
    $soFiles = Get-ChildItem -Recurse $gradleCache -Filter "*.so" -ErrorAction SilentlyContinue
    
    if ($soFiles) {
        Write-Host "✅ Found $($soFiles.Count) native library file(s)" -ForegroundColor Green
        Write-Host ""
        
        foreach ($so in $soFiles) {
            $fullPath = $so.FullName
            $fileName = $so.Name
            $parentDir = $so.Directory.Name
            
            # Xác định architecture
            $arch = $null
            if ($parentDir -like "*arm64-v8a*" -or $parentDir -like "*arm64*") {
                $arch = "arm64-v8a"
            } elseif ($parentDir -like "*armeabi-v7a*" -or $parentDir -like "*armeabi*") {
                $arch = "armeabi-v7a"
            }
            
            if ($arch) {
                # Copy cả libtensorflowlite_jni.so và libtensorflowlite_c.so
                if ($fileName -like "*tensorflowlite*") {
                    # Copy với tên libtensorflowlite_c.so
                    $destPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_c.so"
                    Copy-Item $fullPath -Destination $destPath -Force
                    Write-Host "   ✅ Copied $fileName to $arch\libtensorflowlite_c.so" -ForegroundColor Green
                    $foundLibs = $true
                    
                    # Nếu là libtensorflowlite_jni.so, cũng copy với tên đó
                    if ($fileName -like "*jni*") {
                        $destPathJni = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_jni.so"
                        Copy-Item $fullPath -Destination $destPathJni -Force
                        Write-Host "   ✅ Also copied as libtensorflowlite_jni.so" -ForegroundColor Green
                    }
                }
            }
        }
    }
}

# Nếu không tìm thấy trong cache, thử download từ Maven
if (-not $foundLibs) {
    Write-Host "⚠️ Libraries not found in Gradle cache" -ForegroundColor Yellow
    Write-Host "📥 Downloading from Maven..." -ForegroundColor Yellow
    
    $aarFile = "$jniLibsPath\temp-tflite.aar"
    $extractPath = "$jniLibsPath\temp-extract"
    
    try {
        $aarUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version/tensorflow-lite-$version.aar"
        Invoke-WebRequest -Uri $aarUrl -OutFile $aarFile -ErrorAction Stop
        
        Expand-Archive -Path $aarFile -DestinationPath $extractPath -Force
        
        $jniPath = Join-Path $extractPath "jni"
        if (Test-Path $jniPath) {
            $soFiles = Get-ChildItem -Recurse $jniPath -Filter "*.so"
            
            foreach ($so in $soFiles) {
                $fullPath = $so.FullName
                $fileName = $so.Name
                $relativePath = $fullPath.Replace($jniPath + "\", "")
                
                $arch = $null
                if ($relativePath -like "*arm64-v8a*" -or $relativePath -like "*arm64*") {
                    $arch = "arm64-v8a"
                } elseif ($relativePath -like "*armeabi-v7a*" -or $relativePath -like "*armeabi*") {
                    $arch = "armeabi-v7a"
                }
                
                if ($arch -and $fileName -like "*tensorflowlite*") {
                    # Copy với tên libtensorflowlite_c.so
                    $destPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_c.so"
                    Copy-Item $fullPath -Destination $destPath -Force
                    Write-Host "   ✅ Copied $fileName to $arch\libtensorflowlite_c.so" -ForegroundColor Green
                    $foundLibs = $true
                    
                    # Nếu là libtensorflowlite_jni.so, cũng copy với tên đó
                    if ($fileName -like "*jni*") {
                        $destPathJni = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_jni.so"
                        Copy-Item $fullPath -Destination $destPathJni -Force
                        Write-Host "   ✅ Also copied as libtensorflowlite_jni.so" -ForegroundColor Green
                    }
                }
            }
        }
        
        # Cleanup
        Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
        Remove-Item $aarFile -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "❌ Error downloading: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Kiểm tra kết quả
Write-Host ""
Write-Host "📋 Final check:" -ForegroundColor Cyan
$finalFiles = Get-ChildItem -Recurse $jniLibsPath -Filter "*.so" | Where-Object { $_.DirectoryName -notlike "*temp*" }

if ($finalFiles.Count -gt 0) {
    Write-Host "✅ Native libraries ready:" -ForegroundColor Green
    $finalFiles | ForEach-Object {
        $size = [math]::Round($_.Length / 1KB, 2)
        $sizeStr = "$size KB"
        Write-Host "   $($_.FullName) ($sizeStr)" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "✅ Setup complete! Now rebuild APK:" -ForegroundColor Green
    Write-Host "   flutter clean" -ForegroundColor Yellow
    Write-Host "   flutter build apk --release" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or run app:" -ForegroundColor Yellow
    Write-Host "   flutter run --release" -ForegroundColor Yellow
} else {
    Write-Host "❌ No native libraries found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually:" -ForegroundColor Yellow
    Write-Host "   1. Go to: https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version/"
    Write-Host "   2. Download: tensorflow-lite-$version.aar"
    Write-Host "   3. Extract and copy .so files to:" -ForegroundColor Yellow
    $arm64Path = Join-Path $jniLibsPath "arm64-v8a\libtensorflowlite_c.so"
    $armv7Path = Join-Path $jniLibsPath "armeabi-v7a\libtensorflowlite_c.so"
    Write-Host "      $arm64Path"
    Write-Host "      $armv7Path"
    exit 1
}


# Script để setup native libraries cho TensorFlow Lite
# Chạy: .\setup_native_libs.ps1

Write-Host "🔧 Setting up TensorFlow Lite native libraries..." -ForegroundColor Cyan

$jniLibsPath = "android\app\src\main\jniLibs"
$version = "2.14.0"

# Tạo thư mục
Write-Host "`n📁 Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "$jniLibsPath\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\armeabi-v7a" | Out-Null
Write-Host "✅ Directories created" -ForegroundColor Green

# Download AAR và extract
Write-Host "`n📥 Downloading TensorFlow Lite AAR..." -ForegroundColor Yellow
$aarUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version/tensorflow-lite-$version.aar"
$aarFile = "$jniLibsPath\temp.aar"
$zipFile = "$jniLibsPath\temp.zip"
$extractPath = "$jniLibsPath\temp-extract"

try {
    Invoke-WebRequest -Uri $aarUrl -OutFile $aarFile -ErrorAction Stop
    Write-Host "✅ Downloaded AAR" -ForegroundColor Green
    
    # Rename to zip và extract
    Copy-Item $aarFile $zipFile -Force
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    Write-Host "✅ Extracted AAR" -ForegroundColor Green
    
    # Tìm và copy .so files
    Write-Host "`n🔍 Searching for native libraries..." -ForegroundColor Yellow
    $soFiles = Get-ChildItem -Recurse $extractPath -Filter "libtensorflowlite_c.so"
    
    if ($soFiles.Count -eq 0) {
        Write-Host "⚠️ No .so files found in AAR. Trying alternative method..." -ForegroundColor Yellow
        
        # Thử tìm trong jni folder
        $jniPath = Join-Path $extractPath "jni"
        if (Test-Path $jniPath) {
            $soFiles = Get-ChildItem -Recurse $jniPath -Filter "*.so"
        }
    }
    
    if ($soFiles.Count -gt 0) {
        Write-Host "✅ Found $($soFiles.Count) .so file(s)" -ForegroundColor Green
        
        foreach ($so in $soFiles) {
            $fullPath = $so.FullName
            
            # Xác định architecture từ đường dẫn
            $arch = "unknown"
            if ($fullPath -match "arm64|arm64-v8a") {
                $arch = "arm64-v8a"
            } elseif ($fullPath -match "armeabi|armeabi-v7a") {
                $arch = "armeabi-v7a"
            } elseif ($fullPath -match "x86_64") {
                $arch = "x86_64"
            } elseif ($fullPath -match "x86[^_]") {
                $arch = "x86"
            }
            
            if ($arch -ne "unknown") {
                $destPath = Join-Path "$jniLibsPath\$arch" "libtensorflowlite_c.so"
                Copy-Item $fullPath -Destination $destPath -Force
                Write-Host "   ✅ Copied to $arch" -ForegroundColor Green
            } else {
                Write-Host "   ⚠️ Unknown architecture: $fullPath" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "❌ No .so files found!" -ForegroundColor Red
        Write-Host "`n💡 Manual steps:" -ForegroundColor Yellow
        Write-Host "1. Download libtensorflowlite_c.so from GitHub releases"
        Write-Host "2. Copy to: $jniLibsPath\arm64-v8a\"
        Write-Host "3. Copy to: $jniLibsPath\armeabi-v7a\"
    }
    
    # Cleanup
    Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
    Remove-Item $aarFile, $zipFile -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n💡 Please download manually from:" -ForegroundColor Yellow
    Write-Host "   https://github.com/tensorflow/tensorflow/releases"
    Write-Host "   Look for TensorFlow Lite $version"
}

# Kiểm tra kết quả
Write-Host "`n📋 Final check:" -ForegroundColor Cyan
$finalFiles = Get-ChildItem -Recurse $jniLibsPath -Filter "*.so" | Where-Object { $_.DirectoryName -notlike "*temp*" }
if ($finalFiles.Count -gt 0) {
    Write-Host "✅ Native libraries ready:" -ForegroundColor Green
    $finalFiles | ForEach-Object {
        Write-Host "   $($_.FullName)" -ForegroundColor Cyan
    }
} else {
    Write-Host "❌ No native libraries found!" -ForegroundColor Red
    Write-Host "   Please download manually and place in:" -ForegroundColor Yellow
    Write-Host "   $jniLibsPath\arm64-v8a\libtensorflowlite_c.so"
    Write-Host "   $jniLibsPath\armeabi-v7a\libtensorflowlite_c.so"
}

Write-Host "`n✅ Setup complete!" -ForegroundColor Green










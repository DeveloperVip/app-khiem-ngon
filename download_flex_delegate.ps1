# Script de download va copy flex delegate libraries
# Chay: .\download_flex_delegate.ps1

$ErrorActionPreference = "Stop"

Write-Host "Downloading TensorFlow Lite Flex Delegate Libraries..." -ForegroundColor Cyan
Write-Host ""

$jniLibsPath = "android\app\src\main\jniLibs"
$version = "2.14.0"

# Tao thu muc
Write-Host "Creating directories..." -ForegroundColor Yellow
$archs = @("arm64-v8a", "armeabi-v7a")
foreach ($arch in $archs) {
    $archPath = Join-Path $jniLibsPath $arch
    New-Item -ItemType Directory -Force -Path $archPath | Out-Null
}
Write-Host "Directories created" -ForegroundColor Green
Write-Host ""

# Download AAR tu Maven
Write-Host "Downloading Flex Delegate AAR..." -ForegroundColor Yellow
$aarFile = "$jniLibsPath\temp-flex.aar"
$extractPath = "$jniLibsPath\temp-flex-extract"

try {
    $aarUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite-select-tf-ops/$version/tensorflow-lite-select-tf-ops-$version.aar"
    Write-Host "   URL: $aarUrl"
    Invoke-WebRequest -Uri $aarUrl -OutFile $aarFile -ErrorAction Stop
    
    Write-Host "Extracting AAR..." -ForegroundColor Yellow
    # AAR is a ZIP file, rename to .zip first
    $zipFile = $aarFile.Replace(".aar", ".zip")
    Copy-Item $aarFile $zipFile -Force
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    Remove-Item $zipFile -ErrorAction SilentlyContinue
    
    # Tim .so files trong jni folder
    $jniPath = Join-Path $extractPath "jni"
    if (Test-Path $jniPath) {
        $soFiles = Get-ChildItem -Recurse $jniPath -Filter "*flex*.so"
        
        if ($soFiles) {
            Write-Host "Found $($soFiles.Count) flex delegate library file(s)" -ForegroundColor Green
            Write-Host ""
            
            foreach ($so in $soFiles) {
                $relativePath = $so.FullName.Replace($jniPath + "\", "")
                $arch = $null
                
                if ($relativePath -like "*arm64*") {
                    $arch = "arm64-v8a"
                } elseif ($relativePath -like "*armeabi*") {
                    $arch = "armeabi-v7a"
                }
                
                if ($arch) {
                    $destPath = Join-Path "$jniLibsPath\$arch" $so.Name
                    Copy-Item $so.FullName -Destination $destPath -Force
                    $sizeKB = [math]::Round($so.Length / 1KB, 2)
                    $sizeStr = "$sizeKB KB"
                    Write-Host "  Copied to $arch\$($so.Name) ($sizeStr)" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "No flex delegate libraries found in AAR" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No 'jni' folder found in AAR" -ForegroundColor Red
    }
    
    # Cleanup
    Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
    Remove-Item $aarFile -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "Error downloading: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually:" -ForegroundColor Yellow
    $mavenUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite-select-tf-ops/$version/"
    Write-Host "   1. Go to: $mavenUrl"
    Write-Host "   2. Download: tensorflow-lite-select-tf-ops-$version.aar"
    Write-Host "   3. Extract and copy libtensorflowlite_flex.so to jniLibs"
    exit 1
}

# Kiem tra ket qua
Write-Host ""
Write-Host "Final check:" -ForegroundColor Cyan
$allGood = $true
foreach ($arch in $archs) {
    $archPath = Join-Path $jniLibsPath $arch
    $flexFile = Join-Path $archPath "libtensorflowlite_flex.so"
    
    if (Test-Path $flexFile) {
        $size = [math]::Round((Get-Item $flexFile).Length / 1KB, 2)
        $sizeStr = "$size KB"
        Write-Host "  OK $arch\libtensorflowlite_flex.so ($sizeStr)" -ForegroundColor Green
    } else {
        Write-Host "  FAIL $arch\libtensorflowlite_flex.so - NOT FOUND" -ForegroundColor Red
        $allGood = $false
    }
}

if ($allGood) {
    Write-Host ""
    Write-Host "COMPLETE! Flex delegate libraries ready" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "   flutter clean" -ForegroundColor White
    Write-Host "   flutter build apk --release" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Still missing libraries!" -ForegroundColor Red
}

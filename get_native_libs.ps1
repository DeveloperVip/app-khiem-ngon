# Simple script to download TensorFlow Lite native libraries
# Run: .\get_native_libs.ps1

$jniLibsPath = "android\app\src\main\jniLibs"
$version = "2.14.0"
$baseUrl = "https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/$version"

Write-Host "Downloading TensorFlow Lite native libraries..." -ForegroundColor Cyan

# Create directories
New-Item -ItemType Directory -Force -Path "$jniLibsPath\arm64-v8a" | Out-Null
New-Item -ItemType Directory -Force -Path "$jniLibsPath\armeabi-v7a" | Out-Null

# Download AAR
$aarFile = "$jniLibsPath\temp.aar"
$extractPath = "$jniLibsPath\temp-extract"

try {
    Write-Host "Downloading AAR from Maven..."
    Invoke-WebRequest -Uri "$baseUrl/tensorflow-lite-$version.aar" -OutFile $aarFile
    
    Write-Host "Extracting AAR..."
    $zipFile = "$jniLibsPath\temp.zip"
    Copy-Item $aarFile $zipFile -Force
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    Remove-Item $zipFile -ErrorAction SilentlyContinue
    
    # Find .so files in jni folder
    $jniPath = Join-Path $extractPath "jni"
    if (Test-Path $jniPath) {
        $soFiles = Get-ChildItem -Recurse $jniPath -Filter "libtensorflowlite_c.so"
        
        foreach ($so in $soFiles) {
            $fullPath = $so.FullName
            if ($fullPath -like "*arm64-v8a*" -or $fullPath -like "*arm64*") {
                Copy-Item $fullPath -Destination "$jniLibsPath\arm64-v8a\libtensorflowlite_c.so" -Force
                Write-Host "Copied to arm64-v8a" -ForegroundColor Green
            }
            if ($fullPath -like "*armeabi-v7a*" -or $fullPath -like "*armeabi*") {
                Copy-Item $fullPath -Destination "$jniLibsPath\armeabi-v7a\libtensorflowlite_c.so" -Force
                Write-Host "Copied to armeabi-v7a" -ForegroundColor Green
            }
        }
    }
    
    # Cleanup
    Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue
    Remove-Item $aarFile -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please download manually from GitHub releases" -ForegroundColor Yellow
}

# Check result
$finalFiles = Get-ChildItem -Recurse $jniLibsPath -Filter "*.so" | Where-Object { $_.DirectoryName -notlike "*temp*" }
if ($finalFiles.Count -gt 0) {
    Write-Host "Success! Found $($finalFiles.Count) library file(s)" -ForegroundColor Green
    $finalFiles | ForEach-Object { Write-Host "  $($_.FullName)" }
} else {
    Write-Host "No libraries found. Please download manually." -ForegroundColor Red
}


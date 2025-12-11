# Script để fix FlexDelegate issue
Write-Host "🔧 Đang fix FlexDelegate issue..." -ForegroundColor Cyan

# Bước 1: Clean và rebuild dependencies
Write-Host "`n📦 Bước 1: Clean Gradle cache và rebuild dependencies..." -ForegroundColor Yellow
cd android
./gradlew clean
./gradlew build --refresh-dependencies

# Bước 2: Extract native libraries
Write-Host "`n📦 Bước 2: Extract native libraries từ AAR..." -ForegroundColor Yellow
./gradlew extractTfliteNativeLibs

# Bước 3: Kiểm tra libraries đã extract
Write-Host "`n📋 Bước 3: Kiểm tra libraries đã extract..." -ForegroundColor Yellow
$jniLibsPath = "app/src/main/jniLibs"
if (Test-Path $jniLibsPath) {
    Get-ChildItem $jniLibsPath -Recurse -Filter "*.so" | ForEach-Object {
        $sizeKB = [math]::Round($_.Length / 1024, 2)
        Write-Host "  ✅ $($_.FullName.Replace((Get-Location).Path + '\', '')) ($sizeKB KB)" -ForegroundColor Green
    }
} else {
    Write-Host "  ❌ Không tìm thấy jniLibs folder!" -ForegroundColor Red
}

cd ..

# Bước 4: Clean Flutter và rebuild
Write-Host "`n📦 Bước 4: Clean Flutter và rebuild..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host "`n✅ Hoàn tất! Bây giờ chạy: flutter build apk --debug" -ForegroundColor Green






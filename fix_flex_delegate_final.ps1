# Script để fix FlexDelegate - Giải pháp cuối cùng
Write-Host "🔧 Đang fix FlexDelegate issue - Giải pháp cuối cùng..." -ForegroundColor Cyan

# Bước 1: Clean và rebuild dependencies với version mới
Write-Host "`n📦 Bước 1: Clean Gradle và rebuild với version 2.14.0..." -ForegroundColor Yellow
cd android
./gradlew clean
./gradlew build --refresh-dependencies

# Bước 2: Extract native libraries từ AAR mới
Write-Host "`n📦 Bước 2: Extract native libraries từ AAR version 2.14.0..." -ForegroundColor Yellow
./gradlew extractTfliteNativeLibs

# Bước 3: Kiểm tra libraries
Write-Host "`n📋 Bước 3: Kiểm tra libraries đã extract..." -ForegroundColor Yellow
$jniLibsPath = "app/src/main/jniLibs"
if (Test-Path $jniLibsPath) {
    $totalLibs = 0
    Get-ChildItem $jniLibsPath -Recurse -Filter "*.so" | ForEach-Object {
        $sizeKB = [math]::Round($_.Length / 1024, 2)
        $relativePath = $_.FullName.Replace((Get-Location).Path + '\', '')
        Write-Host "  ✅ $relativePath ($sizeKB KB)" -ForegroundColor Green
        $totalLibs++
    }
    Write-Host "`n  ✅ Tổng cộng: $totalLibs libraries" -ForegroundColor Green
    
    # Kiểm tra flex delegate có tồn tại không
    $flexLibs = Get-ChildItem $jniLibsPath -Recurse -Filter "*flex*.so"
    if ($flexLibs.Count -gt 0) {
        Write-Host "  ✅ Flex delegate libraries đã có!" -ForegroundColor Green
    } else {
        Write-Host "  ❌ KHÔNG TÌM THẤY FLEX DELEGATE LIBRARIES!" -ForegroundColor Red
        Write-Host "  ⚠️ Cần download thủ công từ Maven" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ❌ Không tìm thấy jniLibs folder!" -ForegroundColor Red
}

cd ..

# Bước 4: Clean Flutter
Write-Host "`n📦 Bước 4: Clean Flutter..." -ForegroundColor Yellow
flutter clean
flutter pub get

Write-Host "`n✅ Hoàn tất! Bây giờ chạy: flutter run" -ForegroundColor Green
Write-Host "`n⚠️ LƯU Ý:" -ForegroundColor Yellow
Write-Host "   - Nếu vẫn lỗi, có thể cần extract lại libraries từ version 2.14.0" -ForegroundColor Yellow
Write-Host "   - Hoặc model cần được convert lại để tránh SELECT_TF_OPS" -ForegroundColor Yellow








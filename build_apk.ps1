# Script để build APK release
# Sử dụng: .\build_apk.ps1

Write-Host "🚀 Bắt đầu build APK release..." -ForegroundColor Green

# Kiểm tra Flutter
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter chưa được cài đặt hoặc chưa có trong PATH" -ForegroundColor Red
    exit 1
}

# Build APK release (không cần signing cho test nhanh)
Write-Host "📦 Đang build APK release..." -ForegroundColor Yellow
flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build thành công!" -ForegroundColor Green
    Write-Host "📱 APK được tạo tại: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📤 Các cách chia sẻ APK:" -ForegroundColor Yellow
    Write-Host "   1. Upload lên Google Drive và chia sẻ link"
    Write-Host "   2. Copy vào điện thoại qua USB"
    Write-Host "   3. Gửi qua email và mở trên điện thoại"
    Write-Host ""
    Write-Host "📲 Để cài đặt trên điện thoại:" -ForegroundColor Yellow
    Write-Host "   1. Vào Settings → Security → Bật 'Install unknown apps'"
    Write-Host "   2. Mở file APK đã tải về"
    Write-Host "   3. Tap 'Install'"
} else {
    Write-Host "❌ Build thất bại!" -ForegroundColor Red
    exit 1
}









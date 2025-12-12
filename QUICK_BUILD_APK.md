# 🚀 Hướng dẫn Build APK Nhanh

## Cách 1: Build APK đơn giản (không cần signing - để test)

### Bước 1: Build APK
```bash
cd flutter_application_initial
flutter build apk --release
```

### Bước 2: Tìm file APK
File APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`

### Bước 3: Chia sẻ APK

**Option A: Upload lên Google Drive (Khuyến nghị)**
1. Upload file `app-release.apk` lên Google Drive
2. Click chuột phải → "Get link" → Chọn "Anyone with the link"
3. Copy link và gửi cho người dùng
4. Người dùng mở link trên điện thoại và tải về

**Option B: Copy trực tiếp qua USB**
1. Kết nối điện thoại với máy tính qua USB
2. Copy file `app-release.apk` vào thư mục Download trên điện thoại
3. Mở file trên điện thoại và cài đặt

**Option C: Gửi qua Email**
1. Gửi file `app-release.apk` qua email cho chính mình
2. Mở email trên điện thoại
3. Tải file APK về và cài đặt

### Bước 4: Cài đặt trên điện thoại Android

1. **Cho phép cài đặt từ nguồn không xác định:**
   - Vào **Settings** → **Security** (hoặc **Apps** → **Special access**)
   - Tìm **"Install unknown apps"** hoặc **"Unknown sources"**
   - Bật cho ứng dụng bạn sẽ dùng (File Manager, Chrome, Email, etc.)

2. **Cài đặt APK:**
   - Mở file APK đã tải về
   - Tap **"Install"**
   - Chờ quá trình cài đặt
   - Tap **"Open"** để mở app

---

## Cách 2: Sử dụng script PowerShell (Windows)

1. Mở PowerShell trong thư mục project
2. Chạy:
```powershell
.\build_apk.ps1
```

Script sẽ tự động build và hiển thị đường dẫn đến file APK.

---

## ⚠️ Lưu ý

- APK này **chưa được ký** (unsigned), chỉ phù hợp để test
- Để publish lên Google Play Store, cần build với signing (xem `BUILD_AND_DISTRIBUTE_APK.md`)
- Kích thước APK có thể lớn (~50-100MB) do bao gồm TensorFlow Lite libraries

---

## 🐛 Troubleshooting

**Lỗi: "Execution failed"**
→ Đảm bảo đã chạy `flutter clean` trước khi build:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

**APK không cài được trên điện thoại**
→ Kiểm tra:
- Đã bật "Install unknown apps" chưa?
- File APK có bị hỏng không? (thử tải lại)
- Điện thoại có đủ dung lượng không?

**App crash khi mở**
→ Kiểm tra:
- Đã test trên emulator chưa?
- Logs có lỗi gì không? (dùng `flutter logs`)









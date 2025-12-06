# Sửa lỗi Build trên Windows

## Vấn đề
Firebase Auth plugin trên Windows có lỗi compile do deprecated methods trong C++ SDK.

## Giải pháp

### Giải pháp 1: Chạy trên Android/iOS (Khuyến nghị)
Vì đây là app mobile, nên chạy trên Android hoặc iOS:

```bash
# Android
flutter run -d android

# iOS (chỉ trên macOS)
flutter run -d ios
```

### Giải pháp 2: Cập nhật Dependencies
Đã cập nhật Firebase dependencies lên version mới hơn trong `pubspec.yaml`. Chạy:

```bash
flutter pub get
flutter clean
flutter run
```

### Giải pháp 3: Tạm thời disable Windows (nếu không cần)
Nếu không cần chạy trên Windows, có thể xóa thư mục `windows/` hoặc exclude trong build.

### Giải pháp 4: Sửa Firebase Auth Plugin (Advanced)
Nếu cần chạy trên Windows, có thể cần patch Firebase Auth plugin hoặc đợi bản cập nhật từ Firebase team.

## Đã sửa trong code
- Xóa `updateDisplayName()` call (không cần thiết vì đã lưu vào Firestore)
- Thêm error handling cho Firebase initialization

## Lưu ý
- App được thiết kế chủ yếu cho mobile (Android/iOS)
- Windows support có thể không đầy đủ do hạn chế của Firebase plugins
- Nên test trên Android/iOS để có trải nghiệm tốt nhất






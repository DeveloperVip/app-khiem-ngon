# Hướng dẫn Sửa Lỗi TensorFlow Lite Native Library

## ❌ Lỗi
```
Failed to load dynamic library 'libtensorflowlite_c.so': dlopen failed: library "libtensorflowlite_c.so" not found
```

## 🔍 Nguyên nhân

Lỗi này xảy ra vì:
1. **Android Emulator** (x86_64) có thể không có native library phù hợp
2. Package `tflite_flutter` cần native library nhưng không tự động include
3. Cần rebuild app sau khi thêm dependencies

## ✅ Giải pháp

### Giải pháp 1: Test trên thiết bị thật (Khuyến nghị)

TensorFlow Lite hoạt động tốt nhất trên thiết bị Android thật:
1. Bật USB Debugging trên điện thoại
2. Kết nối điện thoại với máy tính
3. Chạy: `flutter run`

### Giải pháp 2: Đã sửa code để app không crash

Code đã được cập nhật để:
- ✅ App vẫn chạy được khi ML service không khả dụng
- ✅ Hiển thị thông báo thay vì crash
- ✅ Các tính năng khác (lessons, profile) vẫn hoạt động bình thường

### Giải pháp 3: Rebuild app sau khi sửa build.gradle

1. **Đã thêm cấu hình vào `android/app/build.gradle.kts`:**
   ```kotlin
   defaultConfig {
       ndk {
           abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
       }
   }
   
   packaging {
       jniLibs {
           pickFirsts += listOf("lib/**/libtensorflowlite_c.so")
       }
   }
   ```

2. **Clean và rebuild:**
   ```bash
   cd flutter_application_initial
   flutter clean
   flutter pub get
   flutter run
   ```

### Giải pháp 4: Kiểm tra package tflite_flutter

Đảm bảo trong `pubspec.yaml`:
```yaml
dependencies:
  tflite_flutter: ^0.9.0
```

Sau đó:
```bash
flutter pub get
flutter clean
flutter run
```

## 📱 Trạng thái hiện tại

- ✅ **App không crash** khi ML service lỗi
- ✅ **Hiển thị thông báo** thay vì crash
- ✅ **Các tính năng khác** (lessons, profile) hoạt động bình thường
- ⚠️ **ML translation** sẽ không hoạt động trên emulator
- ✅ **ML translation** sẽ hoạt động trên thiết bị thật

## 🧪 Test

1. **Chạy app trên emulator:**
   - App sẽ chạy được
   - Vào tab "Bài học" → Hoạt động ✅
   - Vào tab "Dịch Realtime" → Camera hoạt động nhưng dịch sẽ hiển thị "ML Service không khả dụng" ✅
   - Vào tab "Cá nhân" → Hoạt động ✅

2. **Chạy app trên thiết bị thật:**
   - Tất cả tính năng hoạt động đầy đủ ✅
   - ML translation hoạt động ✅

## 🔧 Troubleshooting

### Nếu vẫn lỗi trên thiết bị thật:

1. **Kiểm tra architecture:**
   ```bash
   adb shell getprop ro.product.cpu.abi
   ```
   - Nếu là `arm64-v8a` → OK
   - Nếu là `armeabi-v7a` → OK
   - Nếu là `x86` hoặc `x86_64` → Có thể không hỗ trợ tốt

2. **Kiểm tra file APK có native library:**
   ```bash
   unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep libtensorflowlite
   ```

3. **Thử downgrade tflite_flutter:**
   ```yaml
   dependencies:
     tflite_flutter: ^0.8.0
   ```

## 📝 Lưu ý

- **Emulator**: ML có thể không hoạt động do thiếu native library
- **Thiết bị thật**: ML sẽ hoạt động tốt
- **App vẫn chạy được** ngay cả khi ML không khả dụng









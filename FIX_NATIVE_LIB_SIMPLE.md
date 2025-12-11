# 🔧 Fix Native Library - Hướng Dẫn Đơn Giản

## ❌ Vấn Đề:
```
Failed to load dynamic library 'libtensorflowlite_c.so': 
dlopen failed: library "libtensorflowlite_c.so" not found
```

## ✅ Giải Pháp Nhanh:

### **Cách 1: Sử dụng Gradle Dependencies (Đã cấu hình)**

Đã thêm vào `build.gradle.kts`:
- `useLegacyPackaging = true`
- Dependencies: `tensorflow-lite:2.14.0`

**Rebuild APK:**
```powershell
cd flutter_application_initial
flutter clean
flutter pub get
flutter build apk --release
```

### **Cách 2: Download Native Libraries Thủ Công**

Nếu cách 1 không hoạt động, download từ GitHub:

1. **Vào trang GitHub Releases:**
   https://github.com/tensorflow/tensorflow/releases

2. **Tìm release có TensorFlow Lite 2.14.0** hoặc version gần nhất

3. **Download file `libtensorflowlite_c.so`** cho các architecture:
   - `arm64-v8a` (thiết bị mới)
   - `armeabi-v7a` (thiết bị cũ)

4. **Copy vào thư mục:**
   ```
   android/app/src/main/jniLibs/
   ├── arm64-v8a/
   │   └── libtensorflowlite_c.so
   └── armeabi-v7a/
       └── libtensorflowlite_c.so
   ```

5. **Rebuild:**
   ```powershell
   flutter clean
   flutter build apk --release
   ```

### **Cách 3: Extract từ Gradle Cache**

Sau khi build, Gradle có thể đã download AAR vào cache:

```powershell
# Tìm trong Gradle cache
$gradleCache = "$env:USERPROFILE\.gradle\caches\modules-2\files-2.1\org.tensorflow\tensorflow-lite"
Get-ChildItem -Recurse $gradleCache -Filter "*.so" | Select-Object FullName
```

Nếu tìm thấy, copy vào `android/app/src/main/jniLibs/`.

## 🔍 Verify Sau Khi Fix

1. **Kiểm tra APK có .so files:**
   ```powershell
   Expand-Archive -Path build\app\outputs\flutter-apk\app-release.apk -DestinationPath apk_check -Force
   Get-ChildItem -Recurse apk_check\lib -Filter "libtensorflowlite*.so"
   ```

2. **Cài và test:**
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   flutter logs | Select-String "interpreter"
   ```

Phải thấy: `✅ Đã khởi tạo interpreter thành công`

## 🆘 Nếu Vẫn Không Được

Thử version khác của TensorFlow Lite trong `build.gradle.kts`:
```kotlin
implementation("org.tensorflow:tensorflow-lite:2.13.0")  // Version cũ hơn
```

Hoặc thử package khác:
```yaml
# pubspec.yaml
tflite_flutter: ^0.10.0  # Version mới hơn
```







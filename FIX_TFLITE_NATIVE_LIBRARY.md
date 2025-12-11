# 🔧 Fix Lỗi libtensorflowlite_c.so Not Found

## ❌ Lỗi:
```
❌ Không thể khởi tạo TensorFlow Lite interpreter: 
Failed to load dynamic library 'libtensorflowlite_c.so': 
dlopen failed: library "libtensorflowlite_c.so" not found
```

## 🔍 Nguyên Nhân:

Plugin `tflite_flutter` có thể không tự động include native libraries trong release build hoặc trên một số thiết bị.

## ✅ Giải Pháp:

### **Bước 1: Thêm Dependencies Vào build.gradle.kts**

Đã thêm vào `android/app/build.gradle.kts`:
```kotlin
dependencies {
    // TensorFlow Lite native libraries
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
}
```

### **Bước 2: Clean và Rebuild**

```bash
cd flutter_application_initial

# Clean project
flutter clean

# Xóa build cache
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/

# Get dependencies lại
flutter pub get

# Rebuild APK
flutter build apk --release
```

### **Bước 3: Kiểm Tra APK Có Chứa Native Libraries**

Sau khi build xong, kiểm tra APK:

```bash
# Giải nén APK (đổi .apk thành .zip)
# Hoặc dùng unzip
unzip build/app/outputs/flutter-apk/app-release.apk -d apk_extracted

# Kiểm tra có file .so không
find apk_extracted/lib -name "libtensorflowlite*.so"
```

Phải có các file:
- `lib/armeabi-v7a/libtensorflowlite_c.so`
- `lib/arm64-v8a/libtensorflowlite_c.so`
- `lib/x86/libtensorflowlite_c.so` (cho emulator)

### **Bước 4: Nếu Vẫn Không Có**

Nếu sau khi rebuild vẫn không có `.so` files, thử:

#### **Option 1: Thêm Explicit Native Libraries**

Tạo thư mục và copy libraries thủ công:
```bash
mkdir -p android/app/src/main/jniLibs/armeabi-v7a
mkdir -p android/app/src/main/jniLibs/arm64-v8a
mkdir -p android/app/src/main/jniLibs/x86
mkdir -p android/app/src/main/jniLibs/x86_64
```

Sau đó download và copy libraries từ:
- TensorFlow Lite releases: https://github.com/tensorflow/tensorflow/releases
- Hoặc từ plugin cache: `~/.pub-cache/hosted/pub.dev/tflite_flutter-0.9.0/android/`

#### **Option 2: Kiểm Tra Plugin Cache**

```bash
# Kiểm tra plugin có native libraries không
ls ~/.pub-cache/hosted/pub.dev/tflite_flutter-0.9.0/android/src/main/jniLibs/
```

Nếu không có, có thể cần:
- Update plugin version
- Hoặc download libraries thủ công

### **Bước 5: Verify Build Config**

Đảm bảo `build.gradle.kts` có:

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

## 🧪 Test Sau Khi Fix

1. **Build APK mới:**
   ```bash
   flutter build apk --release
   ```

2. **Cài APK trên thiết bị thật:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

3. **Xem logs:**
   ```bash
   flutter logs | Select-String "TensorFlow|ML Service"
   ```

4. **Kiểm tra:**
   - Phải thấy: `✅ Đã khởi tạo interpreter thành công`
   - Không thấy: `❌ Không thể khởi tạo TensorFlow Lite interpreter`

## 🔍 Debug Chi Tiết

### **Kiểm Tra Architecture Của Thiết Bị:**

```bash
adb shell getprop ro.product.cpu.abi
```

Output có thể là:
- `arm64-v8a` (phổ biến nhất trên thiết bị mới)
- `armeabi-v7a` (thiết bị cũ)
- `x86` hoặc `x86_64` (emulator)

Đảm bảo APK có native library cho architecture đó!

### **Kiểm Tra Libraries Trong APK:**

```bash
# List tất cả .so files trong APK
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "\.so$"
```

Phải thấy `libtensorflowlite_c.so` trong các thư mục `lib/armeabi-v7a/`, `lib/arm64-v8a/`, etc.

## ⚠️ Lưu Ý

1. **Plugin Version:**
   - `tflite_flutter: ^0.9.0` có thể có vấn đề với native libraries
   - Có thể cần thử version khác hoặc fork của plugin

2. **Build Type:**
   - Debug build có thể hoạt động nhưng release không
   - Luôn test với release APK

3. **Device Architecture:**
   - Đảm bảo APK có library cho architecture của thiết bị
   - Thiết bị thật thường là `arm64-v8a` hoặc `armeabi-v7a`

## 🆘 Nếu Vẫn Không Được

1. **Thử version khác của tflite_flutter:**
   ```yaml
   tflite_flutter: ^0.10.0  # Hoặc version khác
   ```

2. **Kiểm tra plugin có bug:**
   - Xem issues trên GitHub: https://github.com/am15h/tflite_flutter_plugin/issues

3. **Dùng alternative:**
   - `tflite` package (cũ hơn nhưng stable hơn)
   - Hoặc tích hợp TensorFlow Lite trực tiếp qua platform channel

---

**Sau khi rebuild, test lại và xem logs để verify!** 🚀







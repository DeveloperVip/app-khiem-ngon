# 🔍 Kiểm Tra Native Libraries Trong APK

## ✅ Libraries Đã Có Trong jniLibs

- ✅ `arm64-v8a/libtensorflowlite_c.so` - 3.7 MB
- ✅ `armeabi-v7a/libtensorflowlite_c.so` - 2.7 MB

## 🔧 Cấu Hình Gradle Đã Cập Nhật

Đã thêm:
- ✅ `pickFirsts` để ưu tiên libraries từ jniLibs
- ✅ `useLegacyPackaging = true` để đảm bảo compatibility
- ✅ `sourceSets` để chỉ định đường dẫn jniLibs

## 🚀 Bước Tiếp Theo

### **1. Clean và Rebuild**

```powershell
cd C:\Users\hoang\Project\PTIT\Flutter\flutter_application_initial
flutter clean
flutter build apk --debug
```

### **2. Kiểm Tra Libraries Có Trong APK**

Sau khi build xong, kiểm tra APK:

```powershell
# Extract APK
$apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
$extractPath = "build\app\outputs\flutter-apk\extracted"
New-Item -ItemType Directory -Force -Path $extractPath | Out-Null

# Rename và extract
Copy-Item $apkPath "$extractPath\app.zip" -Force
Expand-Archive -Path "$extractPath\app.zip" -DestinationPath $extractPath -Force

# Kiểm tra .so files
Get-ChildItem -Recurse $extractPath -Filter "libtensorflowlite*.so" | Select-Object FullName
```

**Phải thấy:**
- `lib/arm64-v8a/libtensorflowlite_c.so`
- `lib/armeabi-v7a/libtensorflowlite_c.so`

### **3. Kiểm Tra Trên Device**

Sau khi cài APK lên device:

```powershell
# Kiểm tra libraries trên device
adb shell "ls -la /data/app/com.example.flutter_application_initial*/lib/arm64/lib*.so"
```

Hoặc:

```powershell
# Kiểm tra architecture của device
adb shell getprop ro.product.cpu.abi
```

### **4. Kiểm Tra Logs**

```powershell
flutter logs | Select-String "interpreter|tensorflow|libtensorflowlite"
```

**Kết quả mong đợi:**
```
I/flutter: ✅ Đã khởi tạo interpreter thành công
```

## ⚠️ Nếu Vẫn Lỗi

### **Giải Pháp 1: Kiểm Tra Architecture**

Device có thể đang dùng architecture khác. Kiểm tra:

```powershell
adb shell getprop ro.product.cpu.abi
```

Nếu là `x86` hoặc `x86_64` (emulator), cần thêm libraries cho x86.

### **Giải Pháp 2: Copy Libraries Trực Tiếp**

Nếu Gradle không include libraries, thử copy trực tiếp vào APK:

```powershell
# Extract APK
# Copy libraries vào lib/arm64-v8a/ và lib/armeabi-v7a/
# Repack APK
```

### **Giải Pháp 3: Dùng Dependencies Thay Vì Manual**

Thử bỏ manual jniLibs và chỉ dùng dependencies:

```kotlin
dependencies {
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")
}
```

Và xóa `sourceSets` cho jniLibs.

---

**Lưu ý:** Sau mỗi lần thay đổi cấu hình Gradle, phải `flutter clean` và rebuild lại!







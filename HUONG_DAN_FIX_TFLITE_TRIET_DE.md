# 🔧 Hướng Dẫn Fix TensorFlow Lite - Giải Pháp Triệt Để

## ❌ Lỗi bạn đang gặp:

```
Failed to load dynamic library 'libtensorflowlite_c.so': 
dlopen failed: library "libtensorflowlite_c.so" not found
```

## ✅ Giải Pháp Tự Động (Khuyến Nghị)

### **Bước 1: Chạy Script Tự Động**

```powershell
cd flutter_application_initial
.\fix_tflite_complete.ps1
```

Script sẽ tự động:
- ✅ Tìm libraries trong Gradle cache
- ✅ Download từ Maven nếu không tìm thấy
- ✅ Copy vào đúng thư mục jniLibs
- ✅ Kiểm tra kết quả

### **Bước 2: Extract Libraries từ AAR (Gradle)**

```powershell
cd android
.\gradlew extractTfliteNativeLibs
cd ..
```

Task này sẽ tự động extract libraries từ AAR dependencies và copy vào jniLibs.

### **Bước 3: Clean và Rebuild**

```powershell
flutter clean
flutter build apk --release
```

Hoặc chạy app:
```powershell
flutter run --release
```

---

## 🔍 Giải Pháp Thủ Công (Nếu Script Không Hoạt Động)

### **Bước 1: Download AAR từ Maven**

1. Truy cập: https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/2.14.0/
2. Download: `tensorflow-lite-2.14.0.aar`

### **Bước 2: Extract AAR**

1. Đổi tên file từ `.aar` thành `.zip`
2. Giải nén file zip
3. Vào thư mục `jni/` trong file đã giải nén

### **Bước 3: Copy Libraries**

Copy các file `.so` từ `jni/` vào:

```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── libtensorflowlite_c.so  (từ jni/arm64-v8a/libtensorflowlite_jni.so)
└── armeabi-v7a/
    └── libtensorflowlite_c.so  (từ jni/armeabi-v7a/libtensorflowlite_jni.so)
```

**Lưu ý:** File trong AAR có tên `libtensorflowlite_jni.so`, nhưng cần đổi tên thành `libtensorflowlite_c.so`!

---

## 🔧 Kiểm Tra Sau Khi Fix

### **1. Kiểm tra Libraries có trong jniLibs:**

```powershell
Get-ChildItem -Recurse android\app\src\main\jniLibs -Filter "*.so"
```

Phải thấy:
- `android/app/src/main/jniLibs/arm64-v8a/libtensorflowlite_c.so`
- `android/app/src/main/jniLibs/armeabi-v7a/libtensorflowlite_c.so`

### **2. Kiểm tra Libraries có trong APK:**

Sau khi build APK:

```powershell
# Extract APK
Expand-Archive -Path build\app\outputs\flutter-apk\app-release.apk -DestinationPath apk_check -Force

# Kiểm tra
Get-ChildItem -Recurse apk_check\lib -Filter "libtensorflowlite*.so"

# Cleanup
Remove-Item -Recurse -Force apk_check
```

Phải thấy các file `.so` trong:
- `lib/arm64-v8a/`
- `lib/armeabi-v7a/`

### **3. Test trên Thiết Bị:**

```powershell
flutter logs | Select-String "interpreter"
```

Phải thấy: `✅ Đã khởi tạo interpreter thành công`

---

## ⚠️ Lưu Ý Quan Trọng

1. **File trong AAR có tên `libtensorflowlite_jni.so`**
   - Cần đổi tên thành `libtensorflowlite_c.so` khi copy
   - Hoặc copy cả hai tên (cả `_jni.so` và `_c.so`)

2. **Cần rebuild app sau khi thêm libraries**
   - `flutter clean` trước khi rebuild
   - Đảm bảo libraries được copy vào APK

3. **Kiểm tra build.gradle.kts**
   - Đã có task `extractTfliteNativeLibs` tự động chạy
   - Đã có `sourceSets` để include jniLibs
   - Đã có `packaging` để đảm bảo libraries được include

---

## 🆘 Nếu Vẫn Không Được

### **Option 1: Upgrade tflite_flutter**

Có thể version 0.9.0 có vấn đề. Thử upgrade:

```yaml
# pubspec.yaml
dependencies:
  tflite_flutter: ^0.12.1  # Thay vì 0.9.0
```

Sau đó:
```powershell
flutter pub get
flutter clean
flutter build apk --release
```

### **Option 2: Kiểm tra Architecture của Thiết Bị**

```powershell
adb shell getprop ro.product.cpu.abi
```

Đảm bảo có library cho architecture đó (arm64-v8a hoặc armeabi-v7a).

### **Option 3: Test trên Emulator**

Thử chạy trên Android Emulator để xem có lỗi tương tự không.

---

## 📋 Checklist Cuối Cùng

- [ ] Libraries có trong `jniLibs/arm64-v8a/` và `jniLibs/armeabi-v7a/`
- [ ] Đã chạy `gradlew extractTfliteNativeLibs`
- [ ] Đã `flutter clean`
- [ ] Đã rebuild app (`flutter build apk --release`)
- [ ] Libraries có trong APK (kiểm tra bằng extract APK)
- [ ] Test trên thiết bị và thấy `✅ Đã khởi tạo interpreter thành công`

---

## 🎯 Kết Quả Mong Đợi

Sau khi fix thành công, bạn sẽ thấy trong logs:

```
I/flutter: 📦 Đang khởi tạo TensorFlow Lite interpreter...
I/flutter: ✅ Đã khởi tạo interpreter thành công
```

Và ML service sẽ hoạt động bình thường! 🎉






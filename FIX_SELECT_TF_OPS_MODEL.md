# 🔧 Fix Model SELECT_TF_OPS - "failed precondition"

## ❌ Lỗi bạn đang gặp:

```
Bad state: failed precondition
at Interpreter.allocateTensors
```

## ✅ Nguyên Nhân

Model LSTM được convert với **SELECT_TF_OPS** (cần cho TensorListReserve operations), nhưng runtime Android không có **flex delegate** để hỗ trợ SELECT_TF_OPS.

## ✅ Giải Pháp Đã Thực Hiện

### **1. Thêm Flex Delegate Dependency**

Đã thêm vào `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // Thêm flex delegate để hỗ trợ SELECT_TF_OPS models (LSTM cần)
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.14.0") {
        exclude(group = "com.google.ai.edge.litert")
    }
}
```

### **2. Rebuild App**

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

## 🔍 Nếu Vẫn Còn Lỗi

### **Option 1: Kiểm tra Flex Delegate Libraries có trong APK**

Sau khi build, kiểm tra:

```powershell
# Extract APK
Expand-Archive -Path build\app\outputs\flutter-apk\app-release.apk -DestinationPath apk_check -Force

# Kiểm tra flex delegate libraries
Get-ChildItem -Recurse apk_check\lib -Filter "*flex*"

# Cleanup
Remove-Item -Recurse -Force apk_check
```

Phải thấy: `libtensorflowlite_flex.so` trong các thư mục architecture.

### **Option 2: Thêm Flex Libraries vào jniLibs**

Nếu flex delegate không được tự động include, có thể cần thêm thủ công:

1. **Download flex delegate từ Maven:**
   ```
   https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite-select-tf-ops/2.14.0/
   ```

2. **Extract và copy `libtensorflowlite_flex.so` vào:**
   ```
   android/app/src/main/jniLibs/
   ├── arm64-v8a/
   │   └── libtensorflowlite_flex.so
   └── armeabi-v7a/
       └── libtensorflowlite_flex.so
   ```

### **Option 3: Simplify Model Architecture**

Nếu flex delegate vẫn không hoạt động, có thể cần:
1. Simplify LSTM model (ít layers hơn)
2. Hoặc convert model với cách khác
3. Hoặc sử dụng model đơn giản hơn để test

---

## 📋 Checklist

- [ ] Đã thêm `tensorflow-lite-select-tf-ops:2.14.0` vào dependencies
- [ ] Đã `flutter clean`
- [ ] Đã rebuild app
- [ ] Đã kiểm tra flex delegate libraries có trong APK
- [ ] Test trên thiết bị và kiểm tra logs

---

## 🎯 Kết Quả Mong Đợi

Sau khi thêm flex delegate, bạn sẽ thấy:

```
✅ Đã khởi tạo interpreter thành công
   Input tensors: 1
   Output tensors: 1
   Input shape: [1, 30, 1662]
   Output shape: [1, 3]
```

Và ML service sẽ hoạt động với model LSTM! 🎉






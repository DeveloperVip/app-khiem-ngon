# 📥 Hướng Dẫn Tải libtensorflowlite_c.so

## ✅ Đã Tìm Thấy Trong AAR!

AAR file đã chứa native libraries, nhưng tên file là `libtensorflowlite_jni.so` thay vì `libtensorflowlite_c.so`.

**Đã tự động copy và đổi tên!**

## 🔍 Kiểm Tra

```powershell
Get-ChildItem -Recurse android\app\src\main\jniLibs -Filter "*.so"
```

Phải thấy:
- `android/app/src/main/jniLibs/arm64-v8a/libtensorflowlite_c.so`
- `android/app/src/main/jniLibs/armeabi-v7a/libtensorflowlite_c.so`

## 🚀 Nếu Vẫn Thiếu, Download Thủ Công

### **Cách 1: Từ GitHub Releases (Khuyến Nghị)**

1. **Vào trang releases:**
   ```
   https://github.com/tensorflow/tensorflow/releases
   ```

2. **Tìm release có TensorFlow Lite 2.14.0** (hoặc version gần nhất)

3. **Tìm trong assets:**
   - File `libtensorflowlite_c.so` cho `arm64-v8a`
   - File `libtensorflowlite_c.so` cho `armeabi-v7a`

4. **Download và copy vào:**
   ```
   android/app/src/main/jniLibs/
   ├── arm64-v8a/
   │   └── libtensorflowlite_c.so
   └── armeabi-v7a/
       └── libtensorflowlite_c.so
   ```

### **Cách 2: Từ Maven Repository**

1. **Download AAR:**
   ```
   https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/2.14.0/tensorflow-lite-2.14.0.aar
   ```

2. **Đổi tên thành .zip và giải nén**

3. **Tìm trong thư mục `jni/`:**
   - `jni/arm64-v8a/libtensorflowlite_jni.so` → Copy và đổi tên thành `libtensorflowlite_c.so`
   - `jni/armeabi-v7a/libtensorflowlite_jni.so` → Copy và đổi tên thành `libtensorflowlite_c.so`

4. **Copy vào `android/app/src/main/jniLibs/`**

### **Cách 3: Dùng Script (Đã Tạo)**

```powershell
.\extract_from_aar.ps1
```

Script sẽ tự động:
- Tìm tất cả AAR files trong `jniLibs`
- Extract và copy .so files vào đúng thư mục
- Đổi tên thành `libtensorflowlite_c.so`

## ✅ Sau Khi Có Libraries

1. **Verify:**
   ```powershell
   Get-ChildItem -Recurse android\app\src\main\jniLibs -Filter "libtensorflowlite_c.so"
   ```

2. **Rebuild:**
   ```powershell
   flutter clean
   flutter build apk --release
   ```

3. **Test:**
   ```powershell
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   flutter logs | Select-String "interpreter"
   ```

Phải thấy: `✅ Đã khởi tạo interpreter thành công`

---

**Lưu ý:** File `libtensorflowlite_jni.so` trong AAR có thể là cùng một file với `libtensorflowlite_c.so`, chỉ khác tên. Đã tự động copy và đổi tên rồi!







# 📱 Cách Xem Logs Trên Thiết Bị Thật

## 🔌 Bước 1: Kết Nối Thiết Bị

### **Android:**

1. **Bật USB Debugging trên thiết bị:**
   - Vào **Settings** → **About phone**
   - Tap **Build number** 7 lần để enable Developer options
   - Vào **Settings** → **Developer options**
   - Bật **USB debugging**

2. **Kết nối qua USB:**
   - Cắm cáp USB vào máy tính
   - Trên điện thoại, chọn **Allow USB debugging** khi có popup

3. **Kiểm tra kết nối:**
   ```bash
   adb devices
   ```
   
   Nếu thấy thiết bị, output sẽ là:
   ```
   List of devices attached
   ABC123XYZ    device
   ```

---

## 📋 Bước 2: Xem Logs

### **Cách 1: Dùng `flutter logs` (Khuyên dùng)**

```bash
# Xem logs realtime
flutter logs

# Filter logs của Flutter
flutter logs | Select-String "flutter"

# Filter logs ML Service
flutter logs | Select-String "ML|TensorFlow|model"

# Filter errors
flutter logs | Select-String "❌|ERROR|Exception"
```

### **Cách 2: Dùng `adb logcat`**

```bash
# Xem tất cả logs
adb logcat

# Chỉ xem logs Flutter
adb logcat | Select-String "flutter"

# Filter theo package
adb logcat | Select-String "flutter_application_initial"

# Chỉ xem errors và warnings
adb logcat *:E *:W | Select-String "flutter"

# Clear logs cũ trước
adb logcat -c
adb logcat | Select-String "flutter"
```

### **Cách 3: Lưu Logs Vào File**

```bash
# Lưu tất cả logs
adb logcat > device_logs.txt

# Lưu và filter Flutter logs
adb logcat | Select-String "flutter" > flutter_logs.txt

# Sau đó mở file để xem
notepad flutter_logs.txt
```

---

## 🔍 Logs Quan Trọng Cần Tìm

### **1. ML Service Initialization:**

Tìm các dòng này:
```
I/flutter: 📦 Đang load TensorFlow Lite model...
I/flutter: ✅ Đã load model file thành công (XXXX bytes)
I/flutter: 📦 Đang khởi tạo TensorFlow Lite interpreter...
I/flutter: ✅ Đã khởi tạo interpreter thành công
I/flutter: ✅ ML Service đã được khởi tạo thành công!
```

**Hoặc nếu có lỗi:**
```
I/flutter: ❌ Không thể load model file từ assets: ...
I/flutter: ❌ Không thể khởi tạo TensorFlow Lite interpreter: ...
```

### **2. Translation Service:**

```
I/flutter: ✅ TranslationService đã được khởi tạo thành công
I/flutter: ⚠️ ML Service không sẵn sàng khi translateImage
I/flutter: ❌ Lỗi dịch ảnh: ...
```

### **3. Camera/Realtime:**

```
I/flutter: Error initializing camera: ...
I/flutter: Error processing frame: ...
I/flutter: Error translating camera frame: ...
```

---

## 🐛 Debug Lỗi Realtime Translation

### **Nếu thấy lỗi "ML Service không khả dụng":**

1. **Kiểm tra logs ML Service:**
   ```bash
   flutter logs | Select-String "ML Service|TensorFlow|model"
   ```

2. **Các nguyên nhân thường gặp:**

   **a) Model file không được copy vào APK:**
   ```
   ❌ Không thể load model file từ assets: Unable to load asset
   ```
   **Fix:** 
   - Kiểm tra `pubspec.yaml` có `assets: - assets/models/`
   - Chạy `flutter clean` và `flutter pub get`
   - Rebuild APK: `flutter build apk --release`

   **b) Native library không có trong APK:**
   ```
   ❌ Không thể khởi tạo TensorFlow Lite interpreter: 
   Failed to load dynamic library 'libtensorflowlite_c.so'
   ```
   **Fix:**
   - Kiểm tra `build.gradle.kts` có `ndk.abiFilters`
   - Rebuild APK release
   - Kiểm tra APK có chứa `.so` files trong `lib/` folder

   **c) Model file bị hỏng:**
   ```
   ❌ Không thể khởi tạo TensorFlow Lite interpreter: 
   Invalid model or corrupted file
   ```
   **Fix:**
   - Kiểm tra file `.tflite` có size > 0
   - Re-download hoặc re-convert model

---

## 📱 Xem Logs Trên Thiết Bị (Không Cần USB)

### **Option 1: Wireless Debugging (Android 11+)**

1. Bật **Wireless debugging** trong Developer Options
2. Kết nối:
   ```bash
   adb connect <device-ip>:5555
   flutter logs
   ```

### **Option 2: Dùng Log Viewer App**

Cài app như:
- **Log Viewer** (Google Play)
- **Logcat Reader** (Google Play)

Sau đó mở app và xem logs trực tiếp trên điện thoại.

---

## 🎯 Quick Commands

```bash
# 1. Kiểm tra thiết bị
adb devices
flutter devices

# 2. Clear logs cũ
adb logcat -c

# 3. Xem logs Flutter
flutter logs

# 4. Filter logs ML
flutter logs | Select-String "ML|TensorFlow"

# 5. Lưu logs vào file
adb logcat > logs.txt
```

---

## 💡 Tips

1. **Clear logs trước khi test:**
   ```bash
   adb logcat -c
   ```
   Sau đó mở app và xem logs mới

2. **Filter theo keyword:**
   ```bash
   flutter logs | Select-String "ML Service|ERROR|❌"
   ```

3. **Xem logs trong thời gian thực:**
   - Mở 2 terminal windows
   - Terminal 1: `flutter logs`
   - Terminal 2: Chạy app hoặc test tính năng

4. **Tìm lỗi cụ thể:**
   ```bash
   # Tìm lỗi camera
   flutter logs | Select-String "camera|Camera"
   
   # Tìm lỗi ML
   flutter logs | Select-String "ML|model|TensorFlow"
   
   # Tìm lỗi network
   flutter logs | Select-String "network|Socket|Supabase"
   ```

---

## 🔧 Troubleshooting

### **Không thấy thiết bị:**

1. **Kiểm tra USB debugging đã bật:**
   - Settings → Developer options → USB debugging

2. **Thử cáp USB khác** (một số cáp chỉ để sạc)

3. **Cài USB drivers** (nếu Windows):
   - Download từ trang chủ nhà sản xuất điện thoại

4. **Restart ADB:**
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### **Logs không hiển thị:**

1. **Đảm bảo app đang chạy:**
   ```bash
   adb shell ps | Select-String "flutter"
   ```

2. **Thử clear và xem lại:**
   ```bash
   adb logcat -c
   flutter logs
   ```

3. **Kiểm tra filter:**
   - Đảm bảo không filter quá nhiều
   - Thử không filter: `flutter logs`

---

Chúc bạn debug thành công! 🚀









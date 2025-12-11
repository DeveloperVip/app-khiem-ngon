# 📋 Hướng Dẫn Xem Logs Flutter App

## 🎯 Các Cách Xem Logs

### 1. **Xem Logs Trong Terminal (Khi Chạy `flutter run`)**

Khi bạn chạy app bằng lệnh:
```bash
flutter run
```

Logs sẽ tự động hiển thị trong terminal. Bạn sẽ thấy:
- ✅ Logs từ `print()` statements
- ✅ Logs từ `debugPrint()`
- ✅ Logs từ Flutter framework
- ✅ Logs từ native code (Android/iOS)

**Ví dụ output:**
```
I/flutter: 📦 Đang load TensorFlow Lite model...
I/flutter: ✅ Đã load model file thành công (1234567 bytes)
I/flutter: 📚 LessonsScreen: build() called
```

---

### 2. **Xem Logs Sau Khi App Đã Chạy (`flutter logs`)**

Nếu app đã chạy và bạn muốn xem logs riêng:

```bash
# Xem logs của tất cả thiết bị
flutter logs

# Xem logs của thiết bị cụ thể
flutter logs -d <device-id>

# Xem logs và filter theo keyword
flutter logs | grep "ML Service"
```

**Lưu ý:** Cần có thiết bị/emulator đang kết nối.

---

### 3. **Xem Logs Trong Android Studio**

1. Mở **Android Studio**
2. Chạy app bằng nút **Run** (▶️)
3. Mở tab **Run** ở dưới cùng
4. Hoặc mở **Logcat** tab (View → Tool Windows → Logcat)
5. Filter logs:
   - Chọn package: `com.example.flutter_application_initial`
   - Hoặc filter theo tag: `flutter`

**Logcat có thể filter theo:**
- **Tag**: `flutter`, `MLService`, etc.
- **Level**: Verbose, Debug, Info, Warn, Error
- **Package**: Tên package của app

---

### 4. **Xem Logs Trong VS Code**

1. Mở **VS Code**
2. Chạy app bằng **F5** hoặc **Run → Start Debugging**
3. Mở **Debug Console** (View → Debug Console)
4. Logs sẽ hiển thị trong Debug Console

**Hoặc dùng terminal tích hợp:**
- Mở terminal trong VS Code (Ctrl + `)
- Chạy `flutter logs`

---

### 5. **Xem Logs Trên Thiết Bị Thật (ADB)**

Nếu bạn đã build APK và cài trên thiết bị thật:

```bash
# Kết nối thiết bị qua USB
# Bật USB Debugging trên thiết bị

# Xem logs realtime
adb logcat

# Filter chỉ logs của Flutter
adb logcat | grep flutter

# Filter logs của app cụ thể
adb logcat | grep "flutter_application_initial"

# Lưu logs vào file
adb logcat > logs.txt

# Xem logs và filter theo level
adb logcat *:E  # Chỉ errors
adb logcat *:W  # Warnings và errors
```

---

### 6. **Xem Logs Trong Code (Debug Mode)**

Trong code Flutter, bạn có thể dùng:

```dart
// Print (hiển thị trong release mode - có thể bị loại bỏ)
print('📦 Đang load model...');

// DebugPrint (chỉ hiển thị trong debug mode)
debugPrint('✅ Model loaded');

// Log với level
import 'dart:developer' as developer;
developer.log('Message', name: 'MLService', level: 1000);
```

---

## 🔍 Các Loại Logs Quan Trọng

### **Logs từ App của Bạn:**

1. **ML Service Logs:**
   ```
   I/flutter: 📦 Đang load TensorFlow Lite model...
   I/flutter: ✅ Đã load model file thành công
   I/flutter: ❌ Không thể load model file từ assets
   ```

2. **Translation Service Logs:**
   ```
   I/flutter: ✅ TranslationService đã được khởi tạo thành công
   I/flutter: ⚠️ ML Service không sẵn sàng khi translateImage
   ```

3. **Lessons Screen Logs:**
   ```
   I/flutter: 📚 LessonsScreen: build() called
   I/flutter: 📚 LessonsScreen: Rendering 5 lessons
   ```

4. **Supabase Logs:**
   ```
   I/flutter: 📚 Loading 5 lessons...
   I/flutter: ✅ Loaded lesson: Bài 1 (3 contents)
   ```

### **Logs từ Flutter Framework:**

- `I/flutter`: Logs từ Dart code
- `D/FlutterJNI`: Logs từ Flutter engine
- `I/Choreographer`: Performance logs

### **Logs từ Native Code:**

- `E/AndroidRuntime`: Crashes và errors
- `W/System`: Warnings từ system
- `D/Camera`: Camera-related logs

---

## 🛠️ Tips & Tricks

### **1. Filter Logs Quan Trọng:**

```bash
# Chỉ xem logs từ Flutter
flutter logs | grep "flutter"

# Xem logs của ML Service
flutter logs | grep "ML Service"

# Xem errors và warnings
flutter logs | grep -E "(ERROR|WARN|❌)"
```

### **2. Lưu Logs Vào File:**

```bash
# Lưu tất cả logs
flutter logs > app_logs.txt

# Lưu và xem cùng lúc
flutter logs | tee app_logs.txt
```

### **3. Clear Logs Trước Khi Test:**

```bash
# Android
adb logcat -c

# Sau đó chạy app và xem logs mới
flutter logs
```

### **4. Xem Logs Của Nhiều Thiết Bị:**

```bash
# List tất cả thiết bị
flutter devices

# Xem logs của thiết bị cụ thể
flutter logs -d <device-id>
```

---

## 📱 Xem Logs Trên Thiết Bị Thật (Không Cần USB)

### **Option 1: Dùng Wireless Debugging (Android 11+)**

1. Bật **Wireless debugging** trong Developer Options
2. Kết nối qua IP:
   ```bash
   adb connect <device-ip>:5555
   flutter logs
   ```

### **Option 2: Dùng Log Viewer App**

Cài app như **Log Viewer** hoặc **Logcat Reader** trên thiết bị để xem logs trực tiếp.

---

## 🐛 Debug Common Issues

### **Không Thấy Logs:**

1. **Kiểm tra thiết bị đã kết nối:**
   ```bash
   flutter devices
   ```

2. **Kiểm tra app đang chạy:**
   ```bash
   adb shell ps | grep flutter
   ```

3. **Restart logcat:**
   ```bash
   adb logcat -c
   flutter logs
   ```

### **Logs Quá Nhiều:**

Filter theo package hoặc tag:
```bash
flutter logs | grep "flutter_application_initial"
```

---

## 📝 Best Practices

1. **Dùng `debugPrint()` thay vì `print()`** cho logs debug
2. **Thêm emoji hoặc prefix** để dễ filter (ví dụ: `📦`, `✅`, `❌`)
3. **Log level phù hợp**: Không log quá nhiều trong production
4. **Group logs**: Dùng prefix như `[MLService]`, `[TranslationService]`

---

## 🎯 Quick Reference

| Mục đích | Lệnh |
|----------|------|
| Xem logs khi chạy app | `flutter run` |
| Xem logs sau khi app chạy | `flutter logs` |
| Filter logs Flutter | `flutter logs \| grep flutter` |
| Xem logs ADB | `adb logcat` |
| Lưu logs vào file | `flutter logs > logs.txt` |
| Clear logs | `adb logcat -c` |
| List thiết bị | `flutter devices` |

---

## 💡 Ví Dụ Thực Tế

### **Xem Logs Khi Test ML Service:**

```bash
# Terminal 1: Chạy app
flutter run

# Terminal 2: Filter logs ML
flutter logs | grep -E "(ML|TensorFlow|model)"
```

### **Debug Lỗi Network:**

```bash
flutter logs | grep -E "(Socket|network|Supabase|API)"
```

### **Xem Logs Performance:**

```bash
flutter logs | grep -E "(Choreographer|frame|performance)"
```

---

Chúc bạn debug thành công! 🚀







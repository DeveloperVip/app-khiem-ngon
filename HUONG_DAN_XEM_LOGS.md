# Hướng Dẫn Xem Logs Flutter App

## Cách 1: Sử dụng Flutter Logs (Khuyến nghị - Không cần ADB)

Flutter có sẵn công cụ xem logs mà không cần cài ADB riêng:

### Xem tất cả logs:

```powershell
flutter logs
```

### Xem logs với filter (chỉ logs từ app):

```powershell
flutter logs | Select-String -Pattern "tflite|flex|MainActivity|MLService|Translation"
```

### Xem logs realtime khi chạy app:

```powershell
# Terminal 1: Chạy app
flutter run

# Terminal 2: Xem logs
flutter logs
```

## Cách 2: Cài đặt ADB (Nếu cần dùng adb logcat)

### Bước 1: Tải Android SDK Platform Tools

1. Vào: https://developer.android.com/tools/releases/platform-tools
2. Download "SDK Platform-Tools for Windows"
3. Giải nén vào thư mục (ví dụ: `C:\Android\platform-tools`)

### Bước 2: Thêm vào PATH

1. Mở PowerShell với quyền Administrator
2. Chạy lệnh:

```powershell
# Thêm vào PATH tạm thời (chỉ cho session hiện tại)
$env:Path += ";C:\Android\platform-tools"

# Hoặc thêm vĩnh viễn (thay C:\Android\platform-tools bằng đường dẫn thực tế)
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Android\platform-tools", "User")
```

3. Đóng và mở lại PowerShell

### Bước 3: Kiểm tra ADB

```powershell
adb version
```

Nếu hiển thị version thì đã thành công.

### Bước 4: Sử dụng ADB

```powershell
# Xem devices
adb devices

# Xem logs với filter
adb logcat | Select-String -Pattern "tflite|flex|MainActivity"

# Xem logs và lưu vào file
adb logcat > logs.txt
```

## Cách 3: Sử dụng Android Studio Logcat

1. Mở Android Studio
2. Kết nối thiết bị/emulator
3. Vào tab **Logcat** ở dưới cùng
4. Filter bằng: `tflite|flex|MainActivity`

## Cách 4: Xem logs trong VS Code/Android Studio

### VS Code với Flutter Extension:

1. Mở VS Code
2. Vào tab **Debug Console** hoặc **Output**
3. Chọn **Flutter** từ dropdown
4. Logs sẽ hiển thị tự động khi chạy app

### Android Studio:

1. Mở project trong Android Studio
2. Chạy app (Run/Debug)
3. Xem logs trong tab **Run** hoặc **Logcat**

## Cách 5: Xem logs từ code (Debug Print)

Thêm vào code để xem logs trực tiếp:

```dart
import 'dart:developer' as developer;

// Thay vì print()
developer.log('Message', name: 'MLService');

// Hoặc với level
developer.log('Error message', name: 'MLService', level: 1000); // ERROR
```

Sau đó filter trong Flutter logs:

```powershell
flutter logs | Select-String -Pattern "MLService"
```

## Kiểm tra Flex Delegate Logs

Sau khi chạy app, tìm các dòng sau trong logs:

### ✅ Thành công:
```
✅ Loaded libtensorflowlite_flex_jni.so
✅ Flex delegate đã sẵn sàng
✅ FlexDelegate sẽ tự động được sử dụng
```

### ❌ Thất bại:
```
❌ Could not load flex delegate
❌ Error loading flex delegate
Select TensorFlow op(s) is(are) not supported
```

## Troubleshooting

### Nếu không thấy logs:

1. Đảm bảo thiết bị/emulator đã kết nối:
   ```powershell
   flutter devices
   ```

2. Đảm bảo app đang chạy:
   ```powershell
   flutter run
   ```

3. Thử restart Flutter:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

### Nếu logs quá nhiều:

Filter cụ thể hơn:

```powershell
# Chỉ xem errors
flutter logs | Select-String -Pattern "ERROR|❌|Error"

# Chỉ xem TensorFlow Lite
flutter logs | Select-String -Pattern "tflite|TensorFlow|Interpreter"

# Chỉ xem Flex Delegate
flutter logs | Select-String -Pattern "flex|Flex|SELECT_TF_OPS"
```

## Lưu ý

- **Flutter logs** là cách đơn giản nhất, không cần cài đặt thêm
- **ADB logcat** cho nhiều tùy chọn filter và control hơn
- **Android Studio Logcat** tốt nhất cho debugging chi tiết


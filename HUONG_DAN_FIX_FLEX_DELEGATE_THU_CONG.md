# Hướng Dẫn Thủ Công Fix Flex Delegate

Nếu app vẫn không khởi tạo được TensorFlow Lite với Flex Delegate, làm theo các bước sau:

## Bước 1: Kiểm tra Native Libraries

1. Mở Android Studio
2. Vào `android/app/src/main/jniLibs/`
3. Kiểm tra các thư mục:
   - `arm64-v8a/` - cho thiết bị 64-bit ARM
   - `armeabi-v7a/` - cho thiết bị 32-bit ARM
   - `x86/` - cho emulator x86
   - `x86_64/` - cho emulator x86_64

4. Mỗi thư mục phải có các file sau:
   - `libtensorflowlite_c.so`
   - `libtensorflowlite_jni.so`
   - `libtensorflowlite_flex_jni.so` ⚠️ **QUAN TRỌNG**

## Bước 2: Download Native Libraries Thủ Công

Nếu thiếu libraries, download từ Maven Central:

### Cách 1: Download từ Maven Central

1. Vào: https://mvnrepository.com/artifact/org.tensorflow/tensorflow-lite-select-tf-ops/2.15.0
2. Click vào "Files" tab
3. Download AAR file: `tensorflow-lite-select-tf-ops-2.15.0.aar`
4. Extract AAR file (đổi extension từ .aar sang .zip và giải nén)
5. Vào thư mục `jni/` trong AAR đã extract
6. Copy các file `.so` vào `android/app/src/main/jniLibs/` theo architecture

### Cách 2: Sử dụng Gradle Task

Chạy trong terminal (từ thư mục `android/app`):

```bash
cd android/app
./gradlew extractTfliteNativeLibs
```

Hoặc trên Windows PowerShell:

```powershell
cd android\app
.\gradlew.bat extractTfliteNativeLibs
```

## Bước 3: Kiểm tra Build.gradle

Mở `android/app/build.gradle.kts` và đảm bảo có:

```kotlin
dependencies {
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.15.0") {
        exclude(group = "com.google.ai.edge.litert")
    }
}
```

## Bước 4: Clean và Rebuild

```bash
cd flutter_application_initial
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter build apk --debug
```

Hoặc trên Windows:

```powershell
cd flutter_application_initial
flutter clean
cd android
.\gradlew.bat clean
cd ..
flutter pub get
flutter build apk --debug
```

## Bước 5: Kiểm tra Logs

Khi chạy app, kiểm tra logcat:

```bash
adb logcat | grep -i "tflite\|flex\|MainActivity"
```

Tìm các dòng:
- `✅ Loaded libtensorflowlite_flex_jni.so` - Thành công
- `❌ Could not load flex delegate` - Thất bại

## Bước 6: Kiểm tra Architecture

Kiểm tra architecture của thiết bị/emulator:

```bash
adb shell getprop ro.product.cpu.abi
```

Kết quả có thể là:
- `arm64-v8a` - Cần libraries trong `jniLibs/arm64-v8a/`
- `armeabi-v7a` - Cần libraries trong `jniLibs/armeabi-v7a/`
- `x86` - Cần libraries trong `jniLibs/x86/`
- `x86_64` - Cần libraries trong `jniLibs/x86_64/`

## Bước 7: Kiểm tra APK

Sau khi build, kiểm tra APK có chứa libraries:

```bash
# Extract APK
unzip -q app-debug.apk -d apk_extracted

# Kiểm tra libraries
find apk_extracted/lib -name "*.so" | grep tensorflow
```

Hoặc trên Windows PowerShell:

```powershell
# Extract APK (cần 7-Zip hoặc WinRAR)
Expand-Archive -Path app-debug.apk -DestinationPath apk_extracted -Force

# Kiểm tra libraries
Get-ChildItem -Path apk_extracted\lib -Recurse -Filter "*.so" | Where-Object { $_.Name -like "*tensorflow*" }
```

## Bước 8: Nếu Vẫn Không Được - Thử Cách Khác

### Option A: Sử dụng TensorFlow Lite không có SELECT_TF_OPS

Convert lại model chỉ dùng TFLITE_BUILTINS (không dùng SELECT_TF_OPS):

```python
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS]
```

⚠️ **Lưu ý:** Model có thể không hoạt động nếu LSTM operations không được hỗ trợ.

### Option B: Sử dụng TensorFlow Lite GPU Delegate

Thay vì Flex Delegate, có thể thử GPU Delegate (nếu thiết bị hỗ trợ):

```kotlin
// Trong MainActivity
System.loadLibrary("tensorflowlite_gpu_delegate")
```

### Option C: Sử dụng TensorFlow Lite với InterpreterOptions

Trong Dart code, thử set options rõ ràng hơn:

```dart
final options = InterpreterOptions();
options.threads = 2;
options.useNnapi = false; // Tắt NNAPI để dùng Flex Delegate
```

## Liên Hệ

Nếu vẫn không được, kiểm tra:
1. Version Flutter: `flutter --version`
2. Version Android SDK: `sdkmanager --list | grep build-tools`
3. Version Gradle: `./gradlew --version`
4. Logs đầy đủ từ logcat


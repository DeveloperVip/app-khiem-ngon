# Fix Dependency Conflict - TensorFlow Lite

## Vấn đề

Lỗi build do conflict giữa:
- `litert` (từ `tflite_flutter` package) 
- `tensorflow-lite` (từ dependency `tensorflow-lite-select-tf-ops`)

Cả hai đều có các class giống nhau → duplicate classes error.

## Giải pháp đã áp dụng

### 1. Xóa dependency `tensorflow-lite` core

Không cần thêm `tensorflow-lite:2.15.0` vì `tflite_flutter` đã có runtime riêng (`litert`).

### 2. Chỉ lấy native libraries từ `tensorflow-lite-select-tf-ops`

Trong `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // Chỉ lấy native libraries (.so files), exclude Java/Kotlin classes
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.15.0") {
        exclude(group = "org.tensorflow", module = "tensorflow-lite")
        exclude(group = "org.tensorflow", module = "tensorflow-lite-api")
        exclude(group = "com.google.ai.edge.litert")
    }
}
```

### 3. Exclude Java/Kotlin classes trong packaging

```kotlin
packaging {
    jniLibs {
        useLegacyPackaging = true
        pickFirsts.add("lib/**/libtensorflowlite_flex_jni.so")
        // Exclude Java/Kotlin classes để tránh conflict
        excludes.add("**/org/tensorflow/lite/**")
    }
}
```

## Kết quả

✅ Build thành công: `Built build\app\outputs\flutter-apk\app-debug.apk`

## Kiểm tra

1. Chạy app:
   ```powershell
   flutter run
   ```

2. Xem logs để kiểm tra Flex Delegate:
   ```powershell
   flutter logs | Select-String -Pattern "flex|Flex|MainActivity"
   ```

3. Tìm các dòng:
   - `✅ Loaded libtensorflowlite_flex_jni.so` = Thành công
   - `❌ Could not load flex delegate` = Cần kiểm tra native libraries

## Lưu ý

- Native libraries (`libtensorflowlite_flex_jni.so`) phải có trong `android/app/src/main/jniLibs/`
- Chỉ cần libraries cho architecture của thiết bị (arm64-v8a hoặc armeabi-v7a)
- Không cần thêm dependencies Java/Kotlin, chỉ cần native libraries

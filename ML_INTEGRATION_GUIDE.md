# Hướng Dẫn Tích Hợp Model AI vào Flutter App

## Tổng Quan

Dự án này tích hợp model LSTM nhận diện ngôn ngữ ký hiệu (từ dự án Python) vào Flutter app để dịch realtime từ camera.

## Kiến Trúc Tích Hợp

```
Camera Stream (30fps)
    ↓
KeypointsExtractor (MediaPipe)
    ↓
SequenceBuffer (30 frames)
    ↓
MLService (TensorFlow Lite)
    ↓
TranslationResult
```

## Các Bước Tích Hợp

### Bước 1: Convert Model TensorFlow sang TensorFlow Lite

1. **Chạy script convert model:**
   ```bash
   cd Sign-language-dictionary-with-machine-learning
   python convert_to_tflite.py
   ```

2. **Output sẽ tạo ra:**
   - `models/tf_lstm_best.tflite` - Model TensorFlow Lite
   - `models/actions.json` - Metadata về actions

3. **Copy files vào Flutter project:**
   ```bash
   # Copy model file
   cp Sign-language-dictionary-with-machine-learning/models/tf_lstm_best.tflite \
      flutter_application_initial/assets/models/tf_lstm_best.tflite
   
   # Copy metadata
   cp Sign-language-dictionary-with-machine-learning/models/actions.json \
      flutter_application_initial/assets/models/actions.json
   ```

### Bước 2: Cài Đặt Dependencies

Dependencies đã được thêm vào `pubspec.yaml`:
- `tflite_flutter: ^0.10.4` - TensorFlow Lite cho Flutter
- `image: ^4.1.7` - Xử lý ảnh

Chạy:
```bash
cd flutter_application_initial
flutter pub get
```

### Bước 3: Cấu Trúc Files Đã Tạo

#### Services

1. **`lib/services/ml_service.dart`**
   - Load và chạy TensorFlow Lite model
   - Dự đoán từ sequence keypoints
   - Quản lý metadata (actions)

2. **`lib/services/keypoints_extractor.dart`**
   - Extract keypoints từ camera frames
   - **NOTE:** Hiện tại là placeholder với keypoints giả lập
   - **CẦN TÍCH HỢP MEDIAPIPE THỰC TẾ**

3. **`lib/services/sequence_buffer.dart`**
   - Quản lý buffer 30 frames keypoints
   - Tương tự như `deque` trong Python

4. **`lib/services/translation_service.dart`** (Đã cập nhật)
   - Pipeline xử lý: Extract → Buffer → Predict
   - Tích hợp tất cả services

#### Provider

- **`lib/providers/translation_provider.dart`** (Đã cập nhật)
  - Khởi tạo ML service
  - Xử lý kết quả từ camera stream

## Tích Hợp MediaPipe (QUAN TRỌNG)

Hiện tại `KeypointsExtractor` đang dùng keypoints giả lập. Để hoạt động thực tế, bạn cần tích hợp MediaPipe.

### Cách 1: Platform Channel (Khuyến nghị)

Tạo native code (Kotlin/Swift) để gọi MediaPipe:

1. **Android (Kotlin):**
   ```kotlin
   // android/app/src/main/kotlin/.../MediaPipeChannel.kt
   class MediaPipeChannel {
       private val holistic = Holistic()
       
       fun extractKeypoints(imageBytes: ByteArray): List<Double> {
           // Xử lý MediaPipe và trả về keypoints
       }
   }
   ```

2. **iOS (Swift):**
   ```swift
   // ios/Runner/MediaPipeChannel.swift
   class MediaPipeChannel {
       func extractKeypoints(imageBytes: Data) -> [Double] {
           // Xử lý MediaPipe và trả về keypoints
       }
   }
   ```

3. **Flutter:**
   ```dart
   // Trong keypoints_extractor.dart
   final result = await platform.invokeMethod('extractKeypoints', {
     'imageBytes': imageBytes,
   });
   ```

### Cách 2: API Backend

Gửi frame đến backend để xử lý MediaPipe:

```dart
final response = await http.post(
  Uri.parse('https://your-api.com/extract-keypoints'),
  body: base64Encode(imageBytes),
);
final keypoints = json.decode(response.body)['keypoints'];
```

### Cách 3: MediaPipe Flutter Package

Nếu có package Flutter hỗ trợ MediaPipe, sử dụng trực tiếp.

## Sử Dụng

### Khởi Tạo Service

Service sẽ tự động khởi tạo khi cần. Hoặc khởi tạo thủ công:

```dart
final provider = Provider.of<TranslationProvider>(context, listen: false);
await provider.initializeService();
```

### Xử Lý Camera Realtime

Đã được tích hợp trong `CameraScreen`:

```dart
// Tự động xử lý khi camera stream chạy
await provider.translateCameraImage(cameraImage);
```

### Xử Lý Ảnh

```dart
await provider.translateImage(imagePath);
```

## Kiểm Tra Hoạt Động

1. **Kiểm tra model file:**
   - Đảm bảo `assets/models/tf_lstm_best.tflite` tồn tại
   - Đảm bảo `assets/models/actions.json` tồn tại

2. **Test trong app:**
   - Mở màn hình Camera
   - Service sẽ tự động load model khi cần
   - Kiểm tra console logs để xem quá trình khởi tạo

3. **Debug:**
   - Xem logs trong console
   - Kiểm tra `_isServiceInitialized` trong provider
   - Kiểm tra `isReady` trong MLService

## Lưu Ý Quan Trọng

1. **MediaPipe chưa được tích hợp thực tế:**
   - `KeypointsExtractor` hiện đang dùng keypoints giả lập
   - Cần tích hợp MediaPipe để có kết quả chính xác

2. **Model file size:**
   - Model TensorFlow Lite thường nhỏ hơn model .h5
   - Đảm bảo model file được include trong assets

3. **Performance:**
   - Xử lý 5fps (đã được tối ưu trong FrameProcessor)
   - Sequence buffer cần 30 frames mới dự đoán
   - Confidence threshold: 0.6 (có thể điều chỉnh)

4. **Memory:**
   - Sequence buffer tự động quản lý memory
   - History giới hạn 50 items

## Troubleshooting

### Lỗi: "Model file not found"
- Kiểm tra `pubspec.yaml` có include assets
- Kiểm tra file tồn tại trong `assets/models/`
- Chạy `flutter clean` và `flutter pub get`

### Lỗi: "ML Service chưa được khởi tạo"
- Gọi `initializeService()` trước khi sử dụng
- Kiểm tra model file có đúng format không

### Lỗi: "Sequence length không đúng"
- Đảm bảo `SEQUENCE_LENGTH = 30` trong config Python
- Kiểm tra `actions.json` có đúng `sequence_length` không

### Kết quả không chính xác
- Kiểm tra MediaPipe đã được tích hợp chưa
- Kiểm tra keypoints có đúng format không (1662 values)
- Kiểm tra model đã được train đúng chưa

## Tài Liệu Tham Khảo

- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [MediaPipe Documentation](https://mediapipe.dev/)
- [Flutter Platform Channels](https://docs.flutter.dev/development/platform-integration/platform-channels)

## Tác Giả

Tích hợp được thực hiện để kết nối dự án Python AI với Flutter app.


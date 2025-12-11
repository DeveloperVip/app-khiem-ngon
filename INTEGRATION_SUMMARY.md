# Tóm Tắt Cách Tích Hợp Model AI vào Flutter App

## 🎯 Mục Tiêu

Tích hợp model LSTM nhận diện ngôn ngữ ký hiệu (từ dự án Python) vào Flutter app để dịch realtime từ camera.

## 📋 Các Bước Đã Thực Hiện

### 1. **Convert Model TensorFlow → TensorFlow Lite**

**File:** `Sign-language-dictionary-with-machine-learning/convert_to_tflite.py`

- Script Python để convert model `.h5` sang `.tflite`
- Tạo file metadata `actions.json` chứa thông tin về actions
- Output: `models/tf_lstm_best.tflite` và `models/actions.json`

**Cách dùng:**
```bash
cd Sign-language-dictionary-with-machine-learning
python convert_to_tflite.py
```

### 2. **Thêm Dependencies vào Flutter**

**File:** `pubspec.yaml`

Đã thêm:
- `tflite_flutter: ^0.10.4` - TensorFlow Lite cho Flutter
- `image: ^4.1.7` - Xử lý ảnh
- Cấu hình assets để include model files

### 3. **Tạo Services**

#### a. **MLService** (`lib/services/ml_service.dart`)
- Load TensorFlow Lite model từ assets
- Load metadata (actions) từ JSON
- Dự đoán từ sequence keypoints (30 frames)
- Trả về action, confidence, và probabilities

**Chức năng chính:**
```dart
await mlService.initialize(); // Load model
final prediction = await mlService.predict(sequence); // Dự đoán
```

#### b. **KeypointsExtractor** (`lib/services/keypoints_extractor.dart`)
- Extract keypoints từ camera frames
- **⚠️ LƯU Ý:** Hiện tại dùng keypoints giả lập
- **CẦN TÍCH HỢP MEDIAPIPE THỰC TẾ** (xem hướng dẫn trong ML_INTEGRATION_GUIDE.md)

**Chức năng:**
```dart
final keypoints = await extractor.extractKeypoints(cameraImage);
```

#### c. **SequenceBuffer** (`lib/services/sequence_buffer.dart`)
- Quản lý buffer 30 frames keypoints
- Tự động loại bỏ frame cũ khi đầy
- Kiểm tra đủ frames để dự đoán

**Chức năng:**
```dart
buffer.addKeypoints(keypoints); // Thêm frame
if (buffer.isReady()) { // Kiểm tra đủ 30 frames
  final sequence = buffer.getSequence(); // Lấy sequence
}
```

#### d. **TranslationService** (đã cập nhật)
- Pipeline xử lý hoàn chỉnh:
  1. Extract keypoints từ camera frame
  2. Thêm vào sequence buffer
  3. Khi đủ 30 frames → dự đoán bằng ML model
  4. Trả về kết quả nếu confidence >= 0.6

**Pipeline:**
```
CameraImage → KeypointsExtractor → SequenceBuffer → MLService → TranslationResult
```

### 4. **Cập Nhật Provider**

**File:** `lib/providers/translation_provider.dart`

- Thêm method `initializeService()` để khởi tạo ML service
- Cập nhật `translateCameraImage()` để xử lý kết quả null (khi chưa đủ frames)
- Thêm `resetSequence()` để reset buffer khi cần

### 5. **Tạo Hướng Dẫn**

**File:** `ML_INTEGRATION_GUIDE.md`

- Hướng dẫn chi tiết cách tích hợp
- Các bước setup
- Troubleshooting
- Lưu ý về MediaPipe

## 🔄 Luồng Xử Lý Realtime

```
1. Camera stream (30fps)
   ↓
2. FrameProcessor.shouldProcessFrame() → Chọn ~5fps
   ↓
3. KeypointsExtractor.extractKeypoints() → Extract 1662 keypoints
   ↓
4. SequenceBuffer.addKeypoints() → Thêm vào buffer
   ↓
5. Kiểm tra đủ 30 frames?
   ├─ Chưa đủ → Bỏ qua, chờ thêm frames
   └─ Đủ → MLService.predict() → Dự đoán
   ↓
6. Kiểm tra confidence >= 0.6?
   ├─ Không → Bỏ qua
   └─ Có → Trả về TranslationResult
   ↓
7. Update UI với kết quả
```

## 📁 Cấu Trúc Files

```
flutter_application_initial/
├── assets/
│   └── models/
│       ├── tf_lstm_best.tflite  (CẦN COPY TỪ PYTHON PROJECT)
│       └── actions.json          (CẦN COPY TỪ PYTHON PROJECT)
├── lib/
│   ├── services/
│   │   ├── ml_service.dart              ✅ MỚI
│   │   ├── keypoints_extractor.dart     ✅ MỚI
│   │   ├── sequence_buffer.dart         ✅ MỚI
│   │   └── translation_service.dart     ✏️ ĐÃ CẬP NHẬT
│   └── providers/
│       └── translation_provider.dart    ✏️ ĐÃ CẬP NHẬT
└── ML_INTEGRATION_GUIDE.md             ✅ MỚI

Sign-language-dictionary-with-machine-learning/
└── convert_to_tflite.py                ✅ MỚI
```

## ⚠️ Lưu Ý Quan Trọng

### 1. **MediaPipe Chưa Được Tích Hợp Thực Tế**

`KeypointsExtractor` hiện đang dùng keypoints giả lập. Để hoạt động thực tế, cần:

- **Cách 1:** Tích hợp MediaPipe qua Platform Channel (native code)
- **Cách 2:** Gọi API backend để xử lý MediaPipe
- **Cách 3:** Dùng package Flutter hỗ trợ MediaPipe (nếu có)

Xem chi tiết trong `ML_INTEGRATION_GUIDE.md`.

### 2. **Model Files Cần Copy**

Sau khi chạy `convert_to_tflite.py`, cần copy files:
- `models/tf_lstm_best.tflite` → `flutter_application_initial/assets/models/`
- `models/actions.json` → `flutter_application_initial/assets/models/`

### 3. **Performance**

- Xử lý 5fps (đã tối ưu)
- Cần 30 frames mới dự đoán (khoảng 6 giây với 5fps)
- Confidence threshold: 0.6 (có thể điều chỉnh)

## 🚀 Cách Sử Dụng

### Bước 1: Convert Model
```bash
cd Sign-language-dictionary-with-machine-learning
python convert_to_tflite.py
```

### Bước 2: Copy Model Files
```bash
cp models/tf_lstm_best.tflite ../flutter_application_initial/assets/models/
cp models/actions.json ../flutter_application_initial/assets/models/
```

### Bước 3: Install Dependencies
```bash
cd flutter_application_initial
flutter pub get
```

### Bước 4: Chạy App
```bash
flutter run
```

Service sẽ tự động khởi tạo khi cần. Hoặc khởi tạo thủ công:
```dart
final provider = Provider.of<TranslationProvider>(context, listen: false);
await provider.initializeService();
```

## ✅ Checklist

- [x] Script convert model
- [x] Dependencies đã thêm
- [x] MLService đã tạo
- [x] KeypointsExtractor đã tạo (placeholder)
- [x] SequenceBuffer đã tạo
- [x] TranslationService đã cập nhật
- [x] TranslationProvider đã cập nhật
- [x] Hướng dẫn đã tạo
- [ ] Model files đã copy (CẦN LÀM)
- [ ] MediaPipe đã tích hợp (CẦN LÀM)

## 📚 Tài Liệu

- Chi tiết: `ML_INTEGRATION_GUIDE.md`
- Script convert: `Sign-language-dictionary-with-machine-learning/convert_to_tflite.py`

---

**Tác giả:** Tích hợp được thực hiện để kết nối dự án Python AI với Flutter app.


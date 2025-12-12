# 🔧 Fix Lỗi "Bad state: failed precondition" - TensorFlow Lite Model

## ❌ Lỗi bạn đang gặp:

```
Bad state: failed precondition
```

## ✅ Nguyên Nhân

Lỗi này xảy ra khi:
1. **Model được convert với SELECT_TF_OPS** nhưng runtime không hỗ trợ
2. **Model có operations không được hỗ trợ** trong TFLITE_BUILTINS
3. **Model file không hợp lệ** hoặc bị hỏng

## ✅ Giải Pháp

### **Giải pháp 1: Convert lại model chỉ dùng TFLITE_BUILTINS (Khuyến nghị)**

1. **Chạy script convert mới:**

```bash
cd Sign-language-dictionary-with-machine-learning
python convert_to_tflite_builtins_only.py
```

Script này sẽ convert model **CHỈ dùng TFLITE_BUILTINS** (không dùng SELECT_TF_OPS), tương thích với Flutter.

2. **Copy model mới vào Flutter project:**

```bash
# Copy model file
cp models/tf_lstm_best.tflite ../flutter_application_initial/assets/models/tf_lstm_best.tflite

# Copy metadata (nếu chưa có)
cp models/actions.json ../flutter_application_initial/assets/models/actions.json
```

3. **Rebuild Flutter app:**

```powershell
cd flutter_application_initial
flutter clean
flutter pub get
flutter build apk --release
```

### **Giải pháp 2: Kiểm tra model file**

1. **Kiểm tra model file có hợp lệ:**

```powershell
# Kiểm tra kích thước
Get-Item assets\models\tf_lstm_best.tflite | Select-Object Length

# Kích thước hợp lệ: > 1MB (thường 2-5MB)
```

2. **Thử validate model:**

Có thể dùng Python script để validate:

```python
import tensorflow as tf

# Load và validate model
interpreter = tf.lite.Interpreter(model_path="tf_lstm_best.tflite")
interpreter.allocate_tensors()

# Kiểm tra input/output
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input:", input_details)
print("Output:", output_details)
```

### **Giải pháp 3: Thử với model đơn giản hơn**

Nếu model LSTM quá phức tạp, có thể cần:
1. Simplify model architecture
2. Giảm số lượng LSTM layers
3. Hoặc sử dụng model khác đơn giản hơn để test

---

## 🔍 Debug Chi Tiết

### **Kiểm tra logs:**

```powershell
flutter logs | Select-String "interpreter|model|tflite"
```

Xem có thông tin gì về:
- Model size
- Input/output shapes
- Lỗi cụ thể

### **Kiểm tra model trong code:**

Code đã được cải thiện để log chi tiết:
- Model size
- Input/output tensor shapes
- Error messages chi tiết

---

## 📋 Checklist

- [ ] Đã thử convert lại model với TFLITE_BUILTINS only
- [ ] Đã copy model mới vào Flutter project
- [ ] Đã rebuild app (`flutter clean` + `flutter build`)
- [ ] Đã kiểm tra model file có hợp lệ (> 1MB)
- [ ] Đã kiểm tra logs để xem lỗi chi tiết

---

## 🎯 Kết Quả Mong Đợi

Sau khi convert lại model với TFLITE_BUILTINS only, bạn sẽ thấy:

```
✅ Đã khởi tạo interpreter thành công
   Input tensors: 1
   Output tensors: 1
   Input shape: [1, 30, 126]
   Output shape: [1, 3]
```

Và ML service sẽ hoạt động bình thường! 🎉








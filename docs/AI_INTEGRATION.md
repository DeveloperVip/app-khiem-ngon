# TÍCH HỢP AI LÊN MOBILE (AI Integration & Deployment)

## 1. Lựa chọn công nghệ: TensorFlow Lite (TFLite) trên Mobile
*   **Tại sao TFLite?**
    *   Tối ưu hóa cực tốt cho thiết bị di động (ARM Architecture).
    *   Hỗ trợ chạy Offline (On-device Inference), không cần internet, bảo mật dữ liệu và độ trễ thấp (Low Latency).

## 2. Thách thức lớn: Flex Delegate & Select TF Ops
### Vấn đề
Mô hình AI sử dụng các toán tử nâng cao của TensorFlow (LSTM/Transformer layers, Matrix operations phức tạp) mà TFLite Core (phiên bản rút gọn) không hỗ trợ mặc định.

### Giải pháp kỹ thuật
1.  **Enable Flex Delegate:** Kích hoạt thư viện mở rộng `FlexDelegate` trong Interpreter Options.
2.  **Native Build Configuration:**
    *   Cấu hình `build.gradle` để không nén file model (`aaptOptions { noCompress 'tflite' }`) giúp việc load model nhanh hơn (Memory Mapping).
    *   Thêm dependency `implementation 'com.google.ai.edge.litert:litert:1.0.1'` (hoặc tương đương) trong Android native để hỗ trợ runtime.

## 3. Quy trình nạp và chạy Model (Inference Flow)
1.  **Load Model:** Khởi tạo `Interpreter` từ file `.tflite` trong assets.
2.  **Allocate Tensors:** Cấp phát vùng nhớ cho Input và Output tensors.
    *   **Input Tensor:** Shape `[1, 30, 1662]` (Batch size 1, 30 time steps, 1662 features).
    *   **Output Tensor:** Shape `[1, Num_Classes]` (Xác suất của từng hành động).
3.  **Inference (Dự đoán):**
    *   Copy dữ liệu từ Sequence Buffer vào Input Tensor.
    *   Chạy `interpreter.run()`.
    *   Đọc kết quả từ Output Tensor.
4.  **Post-processing:**
    *   Tìm chỉ số (index) có xác suất cao nhất (ArgMax).
    *   Map chỉ số sang tên hành động (Label Mapping).
    *   Kiểm tra ngưỡng tin cậy (Confidence Threshold) trước khi quyết định hiển thị.

## 4. Tối ưu hiệu năng (Performance Optimization)
*   **Threading:** Chạy inference trên luồng riêng, không phải UI thread.
*   **Reuse Interpreter:** Chỉ khởi tạo model một lần duy nhất lúc mở app, tái sử dụng cho các lần dịch sau (Singleton Pattern).
*   **Native Libraries ABI:** Cấu hình `ndk.abiFilters 'armeabi-v7a', 'arm64-v8a'` để đảm bảo app chỉ load đúng thư viện C++ tương thích với phần cứng điện thoại, tránh crash.

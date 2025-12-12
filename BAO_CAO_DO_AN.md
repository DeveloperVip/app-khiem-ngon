# BÁO CÁO CHI TIẾT ĐỒ ÁN: ỨNG DỤNG HỖ TRỢ NGƯỜI KHIẾM THÍNH (SIGN LANGUAGE TRANSLATOR)

## 1. TỔNG QUAN DỰ ÁN
Dự án phát triển ứng dụng di động hỗ trợ người khiếm thính giao tiếp thông qua việc dịch ngôn ngữ ký hiệu sang văn bản theo thời gian thực (Realtime) và cung cấp công cụ học tập.

**Công nghệ sử dụng:**
*   **Mobile Framework:** Flutter (Dart).
*   **AI/ML:** TensorFlow Lite (TFLite) chạy mô hình Deep Learning trên thiết bị.
*   **Computer Vision:** Google Mediapipe (thông qua TFLite) để trích xuất điểm xương (keypoints) bàn tay và cơ thể.
*   **Backend & Database:** Supabase (Authentication, Storage, SQL Database).
*   **Native Android:** Kotlin (để xử lý các tác vụ AI chuyên sâu và Camera stream hiệu năng cao).

---

## 2. QUÁ TRÌNH KHỞI TẠO VÀ PHÁT TRIỂN

### Giai đoạn 1: Khởi tạo & Cấu trúc (Initialization)
*   Khởi tạo dự án Flutter với cấu trúc Clean Architecture cơ bản (Screens, Providers, Services, Models).
*   Tích hợp **Supabase**: Thiết lập Authentication (Đăng nhập/Đăng ký) và Database để lưu trữ bài học, lịch sử người dùng.
*   Thiết lập **Camera Package**: Cấu hình `camera` plugin để truy cập phần cứng camera trên Android/iOS.

### Giai đoạn 2: Tích hợp AI Core (AI Integration)
Đây là giai đoạn phức tạp nhất, yêu cầu tích hợp mô hình TensorFlow Lite vào Flutter.
*   **Model:** Sử dụng mô hình LSTM/Transformer đã được huấn luyện với input là chuỗi 30 frames keypoints.
*   **Luồng xử lý (Pipeline):** Camera Stream (30fps) -> Trích xuất Keypoints (Mediapipe) -> Đưa vào Buffer (30 frames) -> TFLite Interpreter -> Kết quả Dịch.

### Giai đoạn 3: Phát triển Tính năng (Feature Development)
*   **Màn hình Camera:**
    *   **Realtime Mode:** Dịch liên tục khi người dùng thực hiện ký hiệu. Ngưỡng tin cậy (Confidence Threshold): 0.8.
    *   **Dictionary Mode:** Chế độ "Từ điển", người dùng bấm nút để ghi lại chính xác 30 frames của một ký hiệu để dịch chính xác hơn. Ngưỡng tin cậy: 0.6.
    *   **Snapshot:** Tự động chụp ảnh khoảnh khắc khi dịch thành công để lưu lại.
*   **Lưu trữ (Storage):**
    *   Quản lý lịch sử dịch (Từ điển) và các file media tải lên.
    *   Cơ chế giới hạn (Quota): Giới hạn 20 items để tiết kiệm bộ nhớ thiết bị và server.
*   **Bài học (Lessons):** Hiển thị danh sách bài học video/ảnh từ Supabase.

---

## 3. CÁC THÁCH THỨC KỸ THUẬT VÀ GIẢI PHÁP (BUGS & FIXES)

Trong quá trình phát triển, dự án đã gặp phải nhiều vấn đề kỹ thuật nghiêm trọng liên quan đến sự tương thích giữa Flutter và Native Android AI Libraries. Dưới đây là chi tiết các vấn đề và cách giải quyết:

### 3.1. Vấn đề: TFLite Flex Delegate Error (`Bad state: failed precondition`)
*   **Mô tả lỗi:** Khi khởi chạy model AI, ứng dụng bị crash với lỗi `failed precondition`. Nguyên nhân là do model sử dụng các toán tử TensorFlow (Select TF Ops) phức tạp mà bộ thư viện TFLite chuẩn trên mobile không hỗ trợ mặc định.
*   **Giải pháp:**
    *   Phải kích hoạt **Flex Delegate** cho TFLite Interpreter.
    *   Cấu hình trong `android/app/build.gradle` để không nén các file `.tflite`.
    *   Sử dụng `InterpreterOptions` trong Dart để thêm delegate hỗ trợ.

### 3.2. Vấn đề: Xung đột thư viện Native (Native Library Conflicts)
*   **Mô tả lỗi:** Lỗi `java.lang.UnsatisfiedLinkError` khi chạy trên một số thiết bị Android thực tế. Do xung đột giữa các thư viện `.so` (C++) của `flutter_tflite`, `mediapipe`, và `camera`.
*   **Giải pháp:**
    *   Cấu hình `ndk.abiFilters` trong `android/app/build.gradle` để chỉ định rõ các kiến trúc hỗ trợ (như `armeabi-v7a`, `arm64-v8a`).
    *   Đảm bảo phiên bản SDK Android và Gradle tương thích.

### 3.3. Vấn đề: Xử lý Camera Stream Realtime (Performance)
*   **Mô tả lỗi:** Xử lý từng frame từ Camera (30 khung hình/giây) gây lag UI, làm ứng dụng bị giật.
*   **Giải pháp:**
    *   Sử dụng **Isolate** (luồng riêng biệt) hoặc xử lý bất đồng bộ (Async) để tính toán AI không chặn UI thread.
    *   Thêm cơ chế **Frame Skipping**: Chỉ xử lý frame mỗi `N` mili-giây (ví dụ 100ms) thay vì xử lý toàn bộ 30 frames/giây để giảm tải CPU.

### 3.4. Vấn đề: Logic Realtime vs Dictionary
*   **Mô tả:** Làm sao để model hiểu được đâu là bắt đầu và kết thúc của một ký hiệu trong luồng livestream liên tục?
*   **Giải pháp:**
    *   Implement **Sequence Buffer (FIFO Queue)**: Một hàng đợi luôn giữ 30 frames gần nhất.
    *   **Realtime:** Liên tục dự đoán dựa trên 30 frames cuối cùng. Nếu độ tin cậy > 80%, hiển thị kết quả.
    *   **Dictionary:** Xóa sạch buffer, bắt buộc người dùng ghi mới đủ 30 frames, sau đó mới dự đoán một lần duy nhất.

### 3.5. Vấn đề: Chuyển đổi định dạng ảnh Camera
*   **Mô tả:** Camera Android trả về định dạng YUV420, trong khi hiển thị và lưu trữ cần JPEG/RGB.
*   **Giải pháp:**
    *   Sử dụng package `image` để convert raw bytes từ YUV sang RGB/JPEG.
    *   Viết Extension method `_saveCameraImageToFile` để xử lý việc này và xoay ảnh đúng chiều (Rotate 90 độ) cho phù hợp với hướng cầm điện thoại.

---

## 4. CẤU TRÚC DỰ ÁN (PROJECT STRUCTURE)

*   `lib/main.dart`: Entry point, khởi tạo App và Providers.
*   `lib/screens/`:
    *   `camera_screen.dart`: Màn hình chính xử lý Camera, AI translation.
    *   `storage_screen.dart`: Màn hình quản lý lịch sử và file tải lên (Tab view).
    *   `upload_screen.dart`: Màn hình tải lên media từ máy.
    *   `lessons_screen.dart`: Màn hình bài học.
*   `lib/services/`:
    *   `translation_service.dart`: Logic core để gọi model AI.
    *   `ml_service.dart`: Wrapper cho TFLite Interpreter.
    *   `dictionary_storage_service.dart`: Quản lý lưu trữ JSON cục bộ.
    *   `supabase_service.dart`: Giao tiếp với Backend.
*   `lib/providers/`:
    *   `translation_provider.dart`: Quản lý state của việc dịch thuật, thông báo cho UI khi có kết quả.
    *   `auth_provider.dart`: Quản lý trạng thái đăng nhập.
*   `android/`: Chứa native code Kotlin cấu hình cho TFLite và Camera permissions.

---
*Báo cáo được tổng hợp dựa trên quá trình phát triển thực tế của dự án.*

# FRONTEND DEVELOPMENT (Flutter Application)

## 1. Kiến trúc ứng dụng (App Architecture)
Dự án áp dụng mô hình kiến trúc **Provider Pattern** kết hợp với tư duy phân tách **Service-Oriented**.

### Cấu trúc thư mục
*   `lib/models/`: Định nghĩa dữ liệu (Data Classes) như `TranslationResult`, `UserUploadModel`.
*   `lib/providers/`: Quản lý trạng thái ứng dụng (State Management) và Business Logic.
    *   `TranslationProvider`: Trung tâm xử lý logic dịch thuật, cầu nối giữa UI và AI Services.
    *   `AuthProvider`: Quản lý phiên đăng nhập người dùng.
*   `lib/screens/`: Giao diện người dùng (UI Screens).
*   `lib/services/`: Các lớp tương tác với bên ngoài (API, Database, Hardware, AI).
*   `lib/widgets/`: Các UI component tái sử dụng.

## 2. Các điểm nhấn về UI/UX (User Interface & Experience)
*   **Realtime Feedback:** Giao diện Camera hiển thị kết quả dịch ngay lập tức với overlay gradient giúp văn bản dễ đọc trên mọi nền.
*   **Mode Switching:** Chuyển đổi mượt mà giữa chế độ Realtime (Stream liên tục) và Dictionary (Ghi hình có chủ đích) ngay trên màn hình Camera.
*   **Visual Indicators:**
    *   Nút ghi hình Dictionary hiển thị số frame đã ghi đếm ngược (0/30).
    *   Thanh trạng thái AI (Ready/Not Ready) giúp người dùng biết khi nào có thể bắt đầu.
    *   Màu sắc cảnh báo (Confidence Score): Xanh (tin cậy cao) vs Cam (tin cậy thấp).

## 3. Quản lý trạng thái (State Management) với Provider
*   Sử dụng `ChangeNotifierProvider` để `TranslationProvider` có thể thông báo update UI ở bất kỳ đâu.
*   **Flow xử lý:**
    1.  UI lắng nghe `TranslationProvider`.
    2.  Camera gửi frame ảnh tới Provider.
    3.  Provider gọi Service xử lý AI (trong Background/Worker).
    4.  Khi có kết quả, Provider cập nhật biến `currentResult` và gọi `notifyListeners()`.
    5.  UI tự động render kết quả mới.

## 4. Tương tác Hardware (Camera & Permissions)
*   Sử dụng package `camera` để điều khiển luồng dữ liệu hình ảnh (YUV420 Stream).
*   Tự động xoay ảnh (Image Rotation) để phù hợp với hướng cầm thiết bị (đặc biệt quan trọng với Android).
*   Xử lý xin quyền (Permission Handling) người dùng thân thiện, giải thích lý do trước khi yêu cầu.

# XỬ LÝ ẢNH & COMPUTER VISION (Image Processing)

## 1. Quy trình xử lý dữ liệu đầu vào (Input Pipeline)

### Vấn đề cốt lõi
Dữ liệu từ Camera Mobile là dạng **Raw Stream (YUV420)**, trong khi các mô hình AI thường yêu cầu ảnh **RGB** hoặc **Keypoints** (tọa độ vector). Việc xử lý cần tốc độ cực cao (30ms/frame) để đạt chuẩn realtime.

### Quy trình (Pipeline)
1.  **Nhận Frame:** Lắng nghe stream từ `cameraController.startImageStream()`.
2.  **Frame Skipping (Tùy chọn):** Chỉ xử lý 1 frame mỗi 3-5 frames nếu thiết bị yếu, tránh quá tải CPU.
3.  **Trích xuất đặc trưng (Feature Extraction - Mediapipe):**
    *   Đưa ảnh vào Mediapipe Holistic (thông qua TFLite wrapper).
    *   **Output:** Mảng vector chứa tọa độ các điểm (landmarks) trên cơ thể:
        *   Pose (Tư thế cơ thể): 33 điểm.
        *   Face (Khuôn mặt): 468 điểm.
        *   Left/Right Hand (Hai bàn tay): 21 điểm mỗi tay.
    *   Tổng số điểm đặc trưng: **1662 keypoints** (x, y).

## 2. Quản lý chuỗi thời gian (Temporal Sequencing)
Ngôn ngữ ký hiệu là động tác **động** (theo thời gian), không phải ảnh tĩnh.
*   **Buffer (Bộ đệm):** Sử dụng một cấu trúc dữ liệu hàng đợi (Deque/Queue) với kích thước cố định **30 frames**.
*   **Sliding Window (Cửa sổ trượt - Realtime Mode):** Khi có frame mới, đẩy vào cuối hàng đợi và loại bỏ frame cũ nhất. Luôn giữ 30 frames gần nhất để dự đoán.
*   **Fixed Window (Cửa sổ cố định - Dictionary Mode):** Xóa sạch hàng đợi, bắt buộc ghi đủ mới 30 frames liên tiếp của một hành động trọn vẹn.

## 3. Chuyển đổi định dạng & Lưu trữ (Image Conversion)
Để lưu "ảnh bằng chứng" cho lịch sử từ điển:
*   **YUV to RGB:** Sử dụng thuật toán chuyển đổi pixel từ không gian màu YUV (hiệu quả truyền tải) sang RGB (hiệu quả hiển thị).
*   **Rotation:** Xử lý metadata xoay (`exif rotation`) vì sensor camera thường đặt lệch 90 độ so với màn hình điện thoại.
*   **Compression:** Nén thành định dạng JPEG để giảm dung lượng lưu trữ trước khi ghi vào bộ nhớ máy.

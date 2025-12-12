# DATABASE & BACKEND ARCHITECTURE (Supabase)

## 1. Tổng quan
Dự án sử dụng **Supabase** làm nền tảng Backend-as-a-Service (BaaS) thay thế cho việc tự xây dựng server truyền thống. Supabase cung cấp PostgreSQL Database, Authentication, và Storage.

## 2. Cấu trúc Cơ sở dữ liệu (PostgreSQL)

### Các bảng chính (Tables)

#### `users` (Managed by Supabase Auth)
*   Bảng hệ thống của Supabase để quản lý thông tin đăng nhập, UUID người dùng.

#### `lessons` (Quản lý bài học)
*   **Mục đích:** Lưu trữ danh sách bài học ngôn ngữ ký hiệu.
*   **Cấu trúc:**
    *   `id`: UUID (Primary Key).
    *   `title`: Tên bài học (Text).
    *   `video_url`: Đường dẫn video bài học (Text).
    *   `thumbnail_url`: Ảnh đại diện (Text).
    *   `description`: Mô tả chi tiết (Text).
    *   `created_at`: Thời gian tạo.

#### `user_uploads` (Lịch sử tải lên của người dùng)
*   **Mục đích:** Lưu trữ thông tin về các file ảnh/video người dùng đã tải lên để dịch.
*   **Cấu trúc:**
    *   `id`: UUID (Primary Key).
    *   `user_id`: UUID (Foreign Key -> `auth.users`), xác định file của ai.
    *   `image_url`: Link ảnh (nếu có).
    *   `video_url`: Link video (nếu có).
    *   `media_type`: Loại file ('image' | 'video').
    *   `translation`: Kết quả dịch văn bản.
    *   `confidence`: Độ tin cậy của bản dịch (Float).
    *   `uploaded_at`: Thời gian tải lên.

## 3. Storage (Lưu trữ file)
*   **Bucket:** `media`
*   **Cấu trúc thư mục:** `uploads/{user_id}/{filename}`
*   **Quyền truy cập (RLS - Row Level Security):**
    *   Chỉ người dùng sở hữu (Authenticated) mới được xem và xóa file của chính mình.
    *   Public Access được bật cho bucket chứa bài học (`lessons`).

## 4. Các vấn đề và giải pháp Backend
*   **Vấn đề:** Quản lý dung lượng lưu trữ miễn phí.
*   **Giải pháp:**
    *   Thực hiện logic kiểm tra số lượng file (Quota Check) ngay tại Client (Flutter) trước khi upload.
    *   Giới hạn mỗi người dùng tối đa 20 uploads.
    *   Sử dụng cơ chế xóa file vật lý trên Storage bucket khi người dùng xóa record trong Database (Database Trigger hoặc Client logic).

## 5. Security (Bảo mật)
*   Sử dụng **Row Level Security (RLS)** của PostgreSQL để đảm bảo người dùng A không thể truy vấn dữ liệu của người dùng B.
*   API Key (Anon Key) được tích hợp trong App, nhưng quyền hạn bị giới hạn bởi RLS policies.

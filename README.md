# Ứng dụng Dịch Ngôn Ngữ Ký Hiệu

Ứng dụng mobile học và dịch ngôn ngữ ký hiệu với Firebase backend.

## Tính năng chính

### 🔐 Authentication
- Đăng ký/Đăng nhập với Email & Password
- Quản lý tài khoản người dùng
- Đăng xuất

### 📚 Hệ thống Bài học
- Danh sách các bài học
- Chi tiết bài học với video/ảnh và bản dịch
- Điều hướng giữa các nội dung trong bài học
- Theo dõi tiến độ học tập
- Bài kiểm tra sau mỗi lesson

### 📷 Dịch Realtime
- Sử dụng camera để dịch ngôn ngữ ký hiệu realtime
- Xử lý frame từ camera mỗi 2 giây

### 👤 Cá nhân hóa
- Upload video/ảnh cá nhân (có giới hạn)
- Dịch các media đã upload
- Xem lịch sử uploads
- Quản lý storage

## Giới hạn Upload

- **Ảnh**: Tối đa 5MB
- **Video**: Tối đa 20MB
- **Số lượng**: Tối đa 50 files/user
- **Tổng dung lượng**: Tối đa 500MB/user

## Cấu trúc Project

```
lib/
├── models/          # Data models
├── services/         # Business logic & Firebase services
├── providers/        # State management (Provider)
├── screens/          # UI screens
│   ├── auth/        # Login/Register screens
│   ├── lessons/     # Lesson related screens
│   └── ...
└── main.dart         # App entry point
```

## Thiết lập

### 1. Cài đặt dependencies

```bash
flutter pub get
```

### 2. Thiết lập Firebase

Xem file [FIREBASE_SETUP.md](FIREBASE_SETUP.md) để biết chi tiết.

**Tóm tắt:**
1. Tạo Firebase project
2. Thêm Android/iOS app
3. Tải `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
4. Cấu hình Firestore và Storage rules
5. Tạo dữ liệu mẫu lessons

### 3. Chạy ứng dụng

```bash
flutter run
```

## Tích hợp Model ML

Để tích hợp model ML của bạn, chỉnh sửa file `lib/services/translation_service.dart`:

- `translateImage()`: Dịch từ ảnh
- `translateVideo()`: Dịch từ video  
- `translateCameraFrame()`: Dịch realtime từ camera

Hiện tại các hàm này đang giả lập kết quả. Thay thế bằng code gọi model thực tế của bạn.

## Dependencies chính

- `firebase_core`: Firebase core
- `firebase_auth`: Authentication
- `cloud_firestore`: Database
- `firebase_storage`: File storage
- `image_picker`: Chọn ảnh/video
- `camera`: Camera access
- `video_player`: Phát video
- `provider`: State management
- `cached_network_image`: Cache images

## Cấu trúc Database

### Firestore Collections

- `users`: Thông tin người dùng
- `lessons`: Bài học
- `user_uploads`: Uploads của người dùng
- `user_progress`: Tiến độ học tập

### Storage

- `user_uploads/{userId}/{mediaType}/{filename}`: Files đã upload

## Lưu ý

- Đảm bảo đã cấu hình đúng Firebase
- Kiểm tra permissions trong AndroidManifest.xml và Info.plist
- Model ML cần được tích hợp vào `translation_service.dart`

## Tác giả

Ứng dụng được phát triển cho mục đích học tập và nghiên cứu.

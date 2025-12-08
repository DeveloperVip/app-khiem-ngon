# Đã chuyển từ Firebase sang Supabase! 🎉

## Những thay đổi chính

### 1. Dependencies
- ✅ Đã xóa: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`
- ✅ Đã thêm: `supabase_flutter`

### 2. Services
- ✅ `auth_service.dart`: Sử dụng Supabase Auth
- ✅ `supabase_service.dart`: Thay thế `firebase_service.dart`
- ✅ Tất cả screens đã được cập nhật để dùng Supabase

### 3. Models
- ✅ Hỗ trợ cả camelCase và snake_case (tương thích ngược)
- ✅ Tự động map giữa Supabase schema (snake_case) và Dart models

## Cần làm ngay

### Bước 1: Cấu hình Supabase Credentials

Mở `lib/config/supabase_config.dart` và thay thế:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Với thông tin từ Supabase Dashboard của bạn.

### Bước 2: Tạo Database Schema

Xem file `SUPABASE_SETUP.md` để biết chi tiết cách:
- Tạo các bảng (users, lessons, user_uploads, user_progress)
- Cấu hình Row Level Security (RLS)
- Tạo Storage bucket
- Tạo dữ liệu mẫu

### Bước 3: Chạy ứng dụng

```bash
flutter pub get
flutter run
```

## So sánh Firebase vs Supabase

| Tính năng | Firebase | Supabase |
|-----------|----------|----------|
| Authentication | ✅ | ✅ |
| Database | Firestore | PostgreSQL |
| Storage | Firebase Storage | Supabase Storage |
| Real-time | ✅ | ✅ |
| RLS | ❌ | ✅ (Built-in) |

## Lợi ích của Supabase

1. **PostgreSQL**: Database mạnh mẽ hơn Firestore
2. **Row Level Security**: Bảo mật tốt hơn với RLS policies
3. **SQL**: Có thể viết SQL queries trực tiếp
4. **Open Source**: Tự host được nếu cần
5. **REST API**: Tự động generate REST API từ database

## Lưu ý

- Đảm bảo đã cấu hình đúng Supabase URL và anon key
- Kiểm tra RLS policies đã được setup đúng
- Storage bucket `user_media` phải được tạo
- Database schema phải khớp với models trong code

## Hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. Supabase credentials đã đúng chưa
2. Database schema đã được tạo chưa
3. RLS policies đã được enable chưa
4. Storage bucket và policies đã được cấu hình chưa

Xem `SUPABASE_SETUP.md` để biết chi tiết cách setup!



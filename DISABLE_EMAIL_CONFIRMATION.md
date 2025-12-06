# Tắt Email Confirmation để Test

## Vấn đề

Khi đăng nhập, bạn gặp lỗi: **"Email chưa được xác nhận"**

## Giải pháp nhanh: Tắt Email Confirmation

Nếu bạn đang trong giai đoạn **development/testing** và muốn test nhanh:

### Bước 1: Vào Supabase Dashboard

1. Mở trình duyệt và vào [Supabase Dashboard](https://app.supabase.com)
2. Chọn project của bạn

### Bước 2: Tắt Email Confirmation

1. Vào **Authentication** (menu bên trái)
2. Click vào **Providers**
3. Tìm và click vào **Email** provider
4. Tìm option **"Enable email confirmations"** hoặc **"Confirm email"**
5. **TẮT** option này (uncheck)
6. Click **Save**

### Bước 3: Test lại

1. Quay lại app
2. Đăng ký tài khoản mới hoặc đăng nhập với tài khoản cũ
3. Bây giờ bạn có thể đăng nhập ngay mà không cần xác nhận email

## Lưu ý quan trọng

⚠️ **Chỉ dùng cho development/testing!**

- Với **production**, nên **BẬT lại** email confirmation và cấu hình SMTP đúng cách
- Email confirmation giúp đảm bảo email của user là hợp lệ và giảm spam

## Nếu muốn giữ Email Confirmation

Nếu bạn muốn giữ email confirmation, bạn cần:

1. **Cấu hình SMTP** trong Supabase (xem `SUPABASE_SMTP_SETUP.md`)
2. **Xác nhận email** của tài khoản đã đăng ký:
   - Kiểm tra email inbox (kể cả spam folder)
   - Click vào link xác nhận
   - Sau đó đăng nhập lại

## Xác nhận email cho tài khoản đã đăng ký

Nếu bạn đã đăng ký nhưng chưa xác nhận email:

1. Kiểm tra email inbox (kể cả spam folder)
2. Tìm email từ Supabase với subject "Confirm your signup"
3. Click vào link xác nhận trong email
4. Quay lại app và đăng nhập

## Nếu không tìm thấy email xác nhận

1. Kiểm tra spam folder
2. Kiểm tra email đã nhập đúng khi đăng ký chưa
3. Thử đăng ký lại với email khác
4. Hoặc tắt email confirmation để test (như hướng dẫn ở trên)


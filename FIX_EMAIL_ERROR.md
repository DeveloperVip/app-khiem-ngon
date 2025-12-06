# Sửa lỗi "Error sending confirmation email"

## Lỗi hiện tại

Khi đăng ký, bạn gặp lỗi:
```
Error sending confirmation email (statusCode: 500)
```

## Nguyên nhân

Lỗi này xảy ra khi Supabase không thể gửi email xác nhận đăng ký. Có thể do:
1. SMTP chưa được cấu hình
2. SMTP credentials sai
3. Email service của Supabase có vấn đề

## Giải pháp

### Giải pháp 1: Tắt Email Confirmation (Nhanh nhất - cho Development)

Nếu bạn đang trong giai đoạn development và không cần email confirmation:

1. Vào **Supabase Dashboard**
2. Vào **Authentication** > **Providers**
3. Click vào **Email** provider
4. Tắt **Enable email confirmations** (hoặc **Confirm email**)
5. Click **Save**

Sau đó bạn có thể đăng ký và đăng nhập ngay mà không cần xác nhận email.

**Lưu ý**: Chỉ dùng cho development/testing. Với production, nên bật lại và cấu hình SMTP đúng.

### Giải pháp 2: Cấu hình SMTP đúng cách

Nếu bạn muốn giữ email confirmation, cần cấu hình SMTP:

#### Bước 1: Kiểm tra SMTP Settings

1. Vào **Settings** > **Auth** > **SMTP Settings**
2. Kiểm tra xem đã điền đầy đủ thông tin chưa:
   - Sender email
   - Host
   - Port
   - Username
   - Password

#### Bước 2: Test SMTP

1. Sau khi Save SMTP settings, Supabase sẽ tự động test
2. Nếu thấy lỗi, kiểm tra lại:
   - **Gmail**: Đảm bảo đã tạo App Password (không dùng password thường)
   - **SendGrid/Resend**: Đảm bảo API Key đúng
   - **Port**: Thử 587 (TLS) hoặc 465 (SSL)
   - **Host**: Kiểm tra đúng host của nhà cung cấp

#### Bước 3: Xem hướng dẫn chi tiết

Xem file `SUPABASE_SMTP_SETUP.md` để biết cách setup SMTP với:
- Gmail
- SendGrid
- Resend
- Mailgun

### Giải pháp 3: Sử dụng Magic Link thay vì Email Confirmation

Nếu SMTP vẫn không hoạt động, bạn có thể:

1. Tắt Email Confirmation
2. Bật **Magic Link** trong Authentication > Providers
3. Users sẽ đăng nhập bằng cách click vào link trong email (không cần password)

## Kiểm tra nhanh

1. **SMTP đã được cấu hình chưa?**
   - Vào Settings > Auth > SMTP Settings
   - Nếu các trường đều trống → Cần cấu hình SMTP

2. **SMTP có hoạt động không?**
   - Sau khi Save, Supabase sẽ hiển thị message thành công hoặc lỗi
   - Nếu lỗi → Kiểm tra lại credentials

3. **Email Confirmation đang bật hay tắt?**
   - Vào Authentication > Providers > Email
   - Nếu bật nhưng SMTP chưa config → Sẽ gặp lỗi

## Khuyến nghị

- **Development**: Tắt Email Confirmation để test nhanh
- **Production**: Cấu hình SMTP đúng cách và bật Email Confirmation

## Sau khi sửa

1. Thử đăng ký lại
2. Nếu vẫn lỗi, kiểm tra:
   - SMTP settings đã Save chưa
   - Credentials đúng chưa
   - Port và Host đúng chưa
3. Xem logs trong Supabase Dashboard > Logs > Auth để biết chi tiết lỗi


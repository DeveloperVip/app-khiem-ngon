# Hướng dẫn sửa lỗi SMTP Gmail

## Vấn đề hiện tại

Từ logs Supabase, tôi thấy lỗi:
```
535 5.7.8 Username and Password not accepted
```

Điều này có nghĩa là **Gmail SMTP credentials trong Supabase đang SAI**.

## Giải pháp: Sửa lại SMTP Settings

### Bước 1: Tạo App Password mới cho Gmail

1. Vào [Google Account](https://myaccount.google.com/)
2. **Security** → **2-Step Verification** (đảm bảo đã BẬT)
3. **App passwords** → **Generate app password**
4. Chọn:
   - **App**: Mail
   - **Device**: Other (Custom name) → Nhập "Supabase"
5. Click **Generate**
6. **Copy password 16 ký tự** (ví dụ: `abcd efgh ijkl mnop`)

### Bước 2: Cập nhật SMTP trong Supabase

1. Vào **Supabase Dashboard**: https://app.supabase.com/project/rymvpaazbgdrudsrufam
2. Vào **Settings** (biểu tượng bánh răng) → **Auth**
3. Scroll xuống phần **SMTP Settings**
4. **Xóa hết** các trường hiện tại và điền lại:

```
Sender email: h1403lovea0711@gmail.com
Sender name: Ứng dụng Dịch Ngôn Ngữ Ký Hiệu
Host: smtp.gmail.com
Port: 587
Username: h1403lovea0711@gmail.com
Password: [Paste App Password 16 ký tự vừa tạo - KHÔNG có khoảng trắng]
Enable secure email change: ON
```

5. **QUAN TRỌNG**: 
   - Password phải là **App Password** (16 ký tự), KHÔNG phải password Gmail thường
   - Xóa tất cả khoảng trắng trong App Password
   - Ví dụ: Nếu App Password là `abcd efgh ijkl mnop` → Nhập `abcdefghijklmnop`

6. Click **Save**

7. Supabase sẽ tự động test SMTP. Nếu thành công sẽ thấy message "SMTP settings saved successfully"

### Bước 3: Test lại

1. Thử đăng ký lại trong app
2. Kiểm tra email (kể cả spam folder)
3. Nếu vẫn lỗi, kiểm tra:
   - App Password đã copy đúng chưa (không có khoảng trắng)
   - 2-Step Verification đã bật chưa
   - Email sender đúng chưa

## Giải pháp tạm thời: Tắt Email Confirmation

Nếu bạn đang trong giai đoạn development và muốn test nhanh:

1. Vào **Authentication** → **Providers**
2. Click vào **Email** provider
3. **Tắt** "Enable email confirmations"
4. Click **Save**

Sau đó bạn có thể đăng ký và đăng nhập ngay mà không cần xác nhận email.

**Lưu ý**: Chỉ dùng cho development. Với production, nên bật lại và cấu hình SMTP đúng.

## Troubleshooting

### Nếu vẫn lỗi "Username and Password not accepted"

1. **Kiểm tra 2-Step Verification**: Phải BẬT mới tạo được App Password
2. **Tạo App Password mới**: Có thể App Password cũ đã bị revoke
3. **Kiểm tra Less Secure Apps**: Không cần bật (App Password đã đủ)
4. **Thử port khác**: 
   - Port 587 (TLS) - Khuyến nghị
   - Port 465 (SSL) - Nếu 587 không hoạt động

### Nếu muốn dùng nhà cung cấp khác

Xem file `SUPABASE_SMTP_SETUP.md` để setup với:
- SendGrid (100 emails/ngày miễn phí)
- Resend (3,000 emails/tháng miễn phí)
- Mailgun (5,000 emails/tháng miễn phí)

## Đã sửa

✅ Function `update_user_storage` đã được cập nhật với `SET search_path = public` để fix security warning

## Tiếp theo

Sau khi sửa SMTP:
1. Test đăng ký lại
2. Kiểm tra email xác nhận có đến không
3. Click link xác nhận
4. Đăng nhập vào app




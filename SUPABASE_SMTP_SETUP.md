# Hướng dẫn cấu hình SMTP trong Supabase

## Tại sao cần SMTP?

Supabase mặc định sử dụng email service của họ, nhưng có giới hạn rate limit. Để gửi email không giới hạn và tự chủ hơn, bạn cần cấu hình SMTP riêng.

## Bước 1: Chuẩn bị thông tin SMTP

Bạn cần có thông tin SMTP từ một trong các nhà cung cấp sau:

### Các nhà cung cấp SMTP phổ biến:

1. **Gmail** (miễn phí, dễ setup)
2. **SendGrid** (miễn phí 100 emails/ngày)
3. **Mailgun** (miễn phí 5,000 emails/tháng)
4. **Amazon SES** (rất rẻ)
5. **Resend** (miễn phí 3,000 emails/tháng)
6. **SMTP của hosting** (nếu bạn có hosting riêng)

## Bước 2: Cấu hình SMTP trong Supabase

### 2.1. Vào Settings

1. Đăng nhập vào [Supabase Dashboard](https://app.supabase.com/)
2. Chọn project của bạn
3. Vào **Settings** (biểu tượng bánh răng ở menu bên trái)
4. Scroll xuống phần **Auth**
5. Tìm mục **SMTP Settings**

### 2.2. Điền thông tin SMTP

Bạn sẽ thấy form với các trường sau:

- **Sender email**: Email sẽ hiển thị là người gửi
- **Sender name**: Tên hiển thị (ví dụ: "Ứng dụng Dịch Ngôn Ngữ Ký Hiệu")
- **Host**: SMTP server host
- **Port**: SMTP port (thường là 587 hoặc 465)
- **Username**: Email/username để đăng nhập SMTP
- **Password**: Password/App password
- **Enable secure email change**: Bật/tắt (khuyến nghị bật)

## Bước 3: Cấu hình theo từng nhà cung cấp

### Option 1: Gmail (Khuyến nghị cho testing)

**Ưu điểm**: Miễn phí, dễ setup
**Nhược điểm**: Giới hạn 500 emails/ngày

#### Cách setup:

1. **Tạo App Password cho Gmail**:
   - Vào [Google Account](https://myaccount.google.com/)
   - Security > 2-Step Verification (bật nếu chưa bật)
   - App passwords > Generate app password
   - Chọn "Mail" và "Other (Custom name)"
   - Copy password được tạo (16 ký tự)

2. **Điền vào Supabase**:
   ```
   Sender email: your-email@gmail.com
   Sender name: Ứng dụng Dịch Ngôn Ngữ Ký Hiệu
   Host: smtp.gmail.com
   Port: 587
   Username: your-email@gmail.com
   Password: [App password vừa tạo]
   Enable secure email change: ON
   ```

3. Click **Save**

### Option 2: SendGrid (Khuyến nghị cho production)

**Ưu điểm**: Miễn phí 100 emails/ngày, dễ scale
**Nhược điểm**: Cần đăng ký tài khoản

#### Cách setup:

1. **Đăng ký SendGrid**:
   - Vào [SendGrid](https://sendgrid.com/)
   - Đăng ký tài khoản miễn phí
   - Verify email và phone number

2. **Tạo API Key**:
   - Vào Settings > API Keys
   - Create API Key
   - Chọn "Full Access" hoặc "Restricted Access" với quyền Mail Send
   - Copy API key

3. **Verify Sender**:
   - Vào Settings > Sender Authentication
   - Single Sender Verification
   - Thêm email của bạn và verify

4. **Điền vào Supabase**:
   ```
   Sender email: verified-email@yourdomain.com
   Sender name: Ứng dụng Dịch Ngôn Ngữ Ký Hiệu
   Host: smtp.sendgrid.net
   Port: 587
   Username: apikey
   Password: [API Key vừa tạo]
   Enable secure email change: ON
   ```

### Option 3: Resend (Khuyến nghị cho production)

**Ưu điểm**: Miễn phí 3,000 emails/tháng, API tốt
**Nhược điểm**: Cần đăng ký

#### Cách setup:

1. **Đăng ký Resend**:
   - Vào [Resend](https://resend.com/)
   - Đăng ký tài khoản
   - Verify email

2. **Tạo API Key**:
   - Vào API Keys
   - Create API Key
   - Copy API key

3. **Add Domain** (hoặc dùng default domain):
   - Vào Domains
   - Add domain hoặc dùng default domain của Resend

4. **Điền vào Supabase**:
   ```
   Sender email: noreply@yourdomain.com (hoặc default domain)
   Sender name: Ứng dụng Dịch Ngôn Ngữ Ký Hiệu
   Host: smtp.resend.com
   Port: 587
   Username: resend
   Password: [API Key vừa tạo]
   Enable secure email change: ON
   ```

### Option 4: Mailgun

**Ưu điểm**: Miễn phí 5,000 emails/tháng
**Nhược điểm**: Cần verify domain

#### Cách setup:

1. **Đăng ký Mailgun**
2. **Verify domain** hoặc dùng sandbox domain
3. **Lấy SMTP credentials**:
   - Vào Sending > Domain Settings
   - Copy SMTP credentials

4. **Điền vào Supabase**:
   ```
   Sender email: noreply@yourdomain.com
   Sender name: Ứng dụng Dịch Ngôn Ngữ Ký Hiệu
   Host: smtp.mailgun.org
   Port: 587
   Username: [SMTP username từ Mailgun]
   Password: [SMTP password từ Mailgun]
   Enable secure email change: ON
   ```

## Bước 4: Test SMTP Configuration

1. Sau khi Save, Supabase sẽ tự động test SMTP
2. Nếu thành công, bạn sẽ thấy message "SMTP settings saved successfully"
3. Nếu lỗi, kiểm tra lại:
   - Username/Password đúng chưa
   - Port đúng chưa (587 cho TLS, 465 cho SSL)
   - Host đúng chưa
   - Firewall có chặn port không

## Bước 5: Cấu hình Email Templates (Tùy chọn)

1. Vào **Authentication** > **Email Templates**
2. Bạn có thể customize các template:
   - **Confirm signup**: Email xác nhận đăng ký
   - **Magic Link**: Email đăng nhập bằng link
   - **Change Email Address**: Email thay đổi địa chỉ
   - **Reset Password**: Email reset mật khẩu

3. Sử dụng các biến:
   - `{{ .ConfirmationURL }}`: Link xác nhận
   - `{{ .Email }}`: Email của user
   - `{{ .Token }}`: Token xác nhận
   - `{{ .SiteURL }}`: URL của site

### Ví dụ template tiếng Việt:

**Subject**: Xác nhận đăng ký tài khoản

**Body**:
```html
<h2>Chào mừng bạn đến với Ứng dụng Dịch Ngôn Ngữ Ký Hiệu!</h2>
<p>Vui lòng click vào link sau để xác nhận email của bạn:</p>
<p><a href="{{ .ConfirmationURL }}">Xác nhận email</a></p>
<p>Nếu bạn không yêu cầu đăng ký, vui lòng bỏ qua email này.</p>
<p>Trân trọng,<br>Đội ngũ phát triển</p>
```

## Bước 6: Test Email

1. Thử đăng ký một tài khoản mới trong app
2. Kiểm tra email inbox (và spam folder)
3. Click vào link xác nhận
4. Đăng nhập lại vào app

## Troubleshooting

### Lỗi "Authentication failed"
- Kiểm tra username/password đúng chưa
- Với Gmail: Đảm bảo đã tạo App Password, không dùng password thường
- Với SendGrid/Resend: Đảm bảo dùng API Key đúng

### Lỗi "Connection timeout"
- Kiểm tra Host và Port đúng chưa
- Kiểm tra firewall có chặn port 587/465 không
- Thử port 465 với SSL thay vì 587 với TLS

### Email không đến
- Kiểm tra spam folder
- Kiểm tra email sender có bị block không
- Với Gmail: Kiểm tra có bị rate limit không
- Với SendGrid/Mailgun: Kiểm tra domain đã verify chưa

### Rate limit vẫn còn
- Nếu vẫn gặp rate limit sau khi setup SMTP, có thể Supabase vẫn đang dùng service mặc định
- Đảm bảo đã Save SMTP settings thành công
- Thử đăng ký lại sau vài phút

## Lưu ý quan trọng

1. **Bảo mật**: Không commit SMTP credentials vào Git
2. **Rate limits**: Mỗi nhà cung cấp có giới hạn riêng
3. **Spam**: Đảm bảo email không bị đánh dấu spam
4. **Domain**: Với production, nên dùng domain riêng thay vì Gmail
5. **Testing**: Luôn test kỹ trước khi deploy production

## Khuyến nghị

- **Development/Testing**: Dùng Gmail với App Password
- **Production**: Dùng SendGrid, Resend, hoặc Mailgun
- **Enterprise**: Dùng Amazon SES hoặc SMTP riêng


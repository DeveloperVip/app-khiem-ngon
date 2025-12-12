# 🔧 Khắc phục lỗi kết nối mạng

## ❌ Lỗi: "SocketFailed host lookup" hoặc "No address associated with hostname"

### Nguyên nhân:
Thiết bị không thể kết nối đến server Supabase. Có thể do:

1. **Không có kết nối internet**
2. **DNS không hoạt động**
3. **Firewall/Network blocking**
4. **Project Supabase bị pause/delete**

### Cách khắc phục:

#### 1. Kiểm tra kết nối internet
- ✅ Đảm bảo thiết bị đã bật WiFi hoặc 4G/5G
- ✅ Thử mở trình duyệt và truy cập một website bất kỳ
- ✅ Kiểm tra xem có ứng dụng khác kết nối internet được không

#### 2. Kiểm tra Supabase Project
- ✅ Vào [Supabase Dashboard](https://app.supabase.com)
- ✅ Kiểm tra project `rymvpaazbgdrudsrufam` có đang hoạt động không
- ✅ Kiểm tra project có bị pause không (Free tier có thể bị pause sau 7 ngày không dùng)
- ✅ Nếu project bị pause, click "Restore" để khôi phục

#### 3. Kiểm tra URL Supabase
- ✅ Mở file `lib/config/supabase_config.dart`
- ✅ Đảm bảo URL đúng: `https://rymvpaazbgdrudsrufam.supabase.co`
- ✅ Kiểm tra anon key có đúng không

#### 4. Thử các giải pháp khác

**Giải pháp A: Restart app**
- Đóng app hoàn toàn
- Mở lại app và thử đăng ký/đăng nhập lại

**Giải pháp B: Thử mạng khác**
- Tắt WiFi, dùng 4G/5G
- Hoặc ngược lại: tắt 4G/5G, dùng WiFi

**Giải pháp C: Restart thiết bị**
- Restart điện thoại
- Mở lại app và thử

**Giải pháp D: Kiểm tra DNS**
- Vào Settings → WiFi → Advanced
- Thử đổi DNS thành 8.8.8.8 (Google DNS) hoặc 1.1.1.1 (Cloudflare)

#### 5. Kiểm tra Firewall/VPN
- ✅ Tắt VPN nếu đang bật
- ✅ Kiểm tra firewall có chặn kết nối không
- ✅ Thử trên mạng khác (không phải công ty/school)

---

## 🔍 Debug Steps

### Bước 1: Kiểm tra Supabase Project Status
1. Vào https://app.supabase.com
2. Login vào tài khoản
3. Tìm project `rymvpaazbgdrudsrufam`
4. Kiểm tra status:
   - ✅ **Active**: Project đang hoạt động
   - ⚠️ **Paused**: Project bị tạm dừng → Click "Restore"
   - ❌ **Deleted**: Project đã bị xóa → Cần tạo project mới

### Bước 2: Test kết nối từ trình duyệt
Mở trình duyệt trên điện thoại và truy cập:
```
https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/
```

Nếu thấy JSON response → Server hoạt động tốt
Nếu không kết nối được → Vấn đề về network/DNS

### Bước 3: Kiểm tra logs trong app
- Mở app và thử đăng ký/đăng nhập
- Xem logs trong console để biết lỗi chi tiết

---

## 📱 Test trên thiết bị khác

Nếu vẫn không được, thử:
1. Test trên thiết bị khác (điện thoại khác, máy tính)
2. Test trên emulator với internet
3. Kiểm tra xem có phải vấn đề của thiết bị cụ thể không

---

## 🆘 Nếu vẫn không được

1. **Kiểm tra Supabase Project:**
   - Vào Dashboard → Settings → API
   - Copy lại URL và anon key mới
   - Update vào `lib/config/supabase_config.dart`

2. **Tạo project Supabase mới:**
   - Nếu project cũ không dùng được
   - Tạo project mới trên Supabase
   - Copy URL và anon key mới
   - Update config và chạy lại SQL scripts

3. **Liên hệ hỗ trợ:**
   - Supabase Support: https://supabase.com/support
   - Hoặc tạo issue trên GitHub

---

## ✅ Checklist nhanh

- [ ] Thiết bị có internet (WiFi/4G/5G)
- [ ] Supabase project đang Active (không bị pause)
- [ ] URL và anon key trong config đúng
- [ ] Đã thử restart app
- [ ] Đã thử restart thiết bị
- [ ] Đã thử mạng khác
- [ ] Không có VPN/Firewall chặn









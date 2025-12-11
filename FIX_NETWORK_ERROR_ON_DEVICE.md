# 🔧 Cách Fix Lỗi "SocketFailed host lookup" trên Thiết Bị Thật

## ❌ Lỗi bạn đang gặp:
```
SocketFailed host lookup: 'rymvpaazbgdrudsrufam.supabase.co'
No address associated with hostname
```

## ✅ Các Cách Fix (Thử theo thứ tự):

### 🔍 Bước 1: Kiểm tra Internet trên Thiết Bị

1. **Mở trình duyệt** trên điện thoại (Chrome, Safari, etc.)
2. **Truy cập** một website bất kỳ (ví dụ: google.com)
3. **Nếu không vào được** → Thiết bị không có internet
   - ✅ Bật WiFi hoặc 4G/5G
   - ✅ Kiểm tra cài đặt mạng
   - ✅ Thử mạng khác

### 🔍 Bước 2: Kiểm tra Supabase Project

**Quan trọng nhất:** Project Supabase có thể bị **PAUSE** (tạm dừng)

1. **Mở trình duyệt** trên máy tính hoặc điện thoại
2. **Truy cập:** https://app.supabase.com
3. **Đăng nhập** vào tài khoản Supabase
4. **Tìm project:** `rymvpaazbgdrudsrufam`
5. **Kiểm tra status:**
   - ✅ **Active** (màu xanh) → Project đang hoạt động
   - ⚠️ **Paused** (màu vàng) → **Click "Restore" để khôi phục**
   - ❌ **Deleted** → Cần tạo project mới

**Lưu ý:** Free tier của Supabase tự động pause project sau 7 ngày không dùng!

### 🔍 Bước 3: Test Kết Nối Supabase

**Trên điện thoại, mở trình duyệt và truy cập:**
```
https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/
```

**Kết quả:**
- ✅ **Thấy JSON response** → Server hoạt động tốt, vấn đề ở app
- ❌ **Không kết nối được** → Vấn đề về network/DNS hoặc project bị pause

### 🔍 Bước 4: Thử Các Giải Pháp Khác

#### Giải pháp A: Restart App
1. **Đóng app hoàn toàn** (swipe away từ recent apps)
2. **Mở lại app**
3. **Thử đăng ký/đăng nhập lại**

#### Giải pháp B: Thử Mạng Khác
1. **Tắt WiFi**, dùng **4G/5G**
2. Hoặc ngược lại: **Tắt 4G/5G**, dùng **WiFi**
3. **Mở lại app** và thử

#### Giải pháp C: Restart Thiết Bị
1. **Restart điện thoại**
2. **Mở lại app** và thử

#### Giải pháp D: Kiểm tra DNS
1. Vào **Settings** → **WiFi**
2. **Long press** vào WiFi đang dùng
3. **Modify network** → **Advanced**
4. **IP Settings** → **Static** (tạm thời)
5. **DNS 1:** `8.8.8.8` (Google DNS)
6. **DNS 2:** `8.8.4.4`
7. **Save** và thử lại

#### Giải pháp E: Tắt VPN/Firewall
- ✅ **Tắt VPN** nếu đang bật
- ✅ **Tắt Firewall** tạm thời để test
- ✅ **Thử trên mạng khác** (không phải công ty/school)

---

## 🎯 Giải Pháp Nhanh Nhất (90% trường hợp)

**Nếu project Supabase bị PAUSE:**

1. Vào https://app.supabase.com
2. Login vào tài khoản
3. Tìm project `rymvpaazbgdrudsrufam`
4. **Click "Restore"** hoặc **"Resume"**
5. Đợi 1-2 phút để project khởi động lại
6. **Mở lại app** trên điện thoại và thử

---

## 🔄 Nếu Vẫn Không Được

### Option 1: Kiểm tra lại Config
1. Mở file `lib/config/supabase_config.dart`
2. Đảm bảo URL đúng: `https://rymvpaazbgdrudsrufam.supabase.co`
3. Kiểm tra anon key có đúng không
4. Rebuild app và cài lại

### Option 2: Tạo Project Supabase Mới
1. Vào https://app.supabase.com
2. **Create new project**
3. Copy **URL** và **anon key** mới
4. Update vào `lib/config/supabase_config.dart`
5. Chạy lại SQL scripts (`DATABASE_SCHEMA_FIXED.sql`)
6. Rebuild app

### Option 3: Test trên Thiết Bị Khác
- Thử trên điện thoại khác
- Hoặc test trên emulator với internet
- Để xác định có phải vấn đề của thiết bị cụ thể không

---

## 📋 Checklist Nhanh

- [ ] Thiết bị có internet (WiFi/4G/5G)
- [ ] Supabase project đang **Active** (không bị pause)
- [ ] Đã thử restart app
- [ ] Đã thử restart thiết bị
- [ ] Đã thử mạng khác (WiFi ↔ 4G)
- [ ] Không có VPN/Firewall chặn
- [ ] URL và anon key trong config đúng

---

## 🆘 Vẫn Không Được?

1. **Kiểm tra logs chi tiết:**
   - Kết nối điện thoại với máy tính
   - Chạy `flutter logs` để xem lỗi chi tiết

2. **Liên hệ hỗ trợ:**
   - Supabase Support: https://supabase.com/support
   - Hoặc tạo issue trên GitHub

3. **Test với project Supabase mới:**
   - Tạo project mới để đảm bảo không phải vấn đề của project cũ







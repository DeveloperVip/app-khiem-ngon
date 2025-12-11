# 🔧 Fix Lỗi Kết Nối Supabase - "Failed host lookup"

## ❌ Lỗi bạn đang gặp:

```
AuthRetryableFetchException(message: ClientException with SocketException: 
Failed host lookup: 'rymvpaazbgdrudsrufam.supabase.co' 
(OS Error: No address associated with hostname, errno = 7))
```

## ✅ Giải Pháp Nhanh Nhất (90% trường hợp)

### **Bước 1: Kiểm tra Supabase Project có bị PAUSE không**

**Đây là nguyên nhân phổ biến nhất!**

1. **Mở trình duyệt** trên máy tính hoặc điện thoại
2. **Truy cập:** https://app.supabase.com
3. **Đăng nhập** vào tài khoản Supabase
4. **Tìm project:** `rymvpaazbgdrudsrufam`
5. **Kiểm tra status:**
   - ✅ **Active** (màu xanh) → Project đang hoạt động
   - ⚠️ **Paused** (màu vàng) → **Click "Restore" để khôi phục**
   - ❌ **Deleted** → Cần tạo project mới

**Lưu ý:** Free tier của Supabase tự động pause project sau 7 ngày không dùng!

### **Bước 2: Đợi 1-2 phút sau khi Restore**

Sau khi click "Restore", đợi 1-2 phút để project khởi động lại.

### **Bước 3: Restart App**

1. **Đóng app hoàn toàn** (swipe away từ recent apps)
2. **Mở lại app**
3. **Thử lại**

---

## 🔍 Các Nguyên Nhân Khác

### **1. Thiết bị không có Internet**

**Kiểm tra:**
- ✅ Bật WiFi hoặc 4G/5G
- ✅ Mở trình duyệt và truy cập google.com
- ✅ Nếu không vào được → Thiết bị không có internet

**Giải pháp:**
- Bật WiFi/4G/5G
- Kiểm tra cài đặt mạng
- Thử mạng khác

### **2. DNS không resolve được**

**Test kết nối Supabase:**

Trên điện thoại, mở trình duyệt và truy cập:
```
https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/
```

**Kết quả:**
- ✅ **Thấy JSON response** → Server hoạt động tốt, vấn đề ở app
- ❌ **Không kết nối được** → Vấn đề về network/DNS hoặc project bị pause

**Giải pháp DNS:**
1. Vào **Settings** → **WiFi**
2. **Long press** vào WiFi đang dùng
3. **Modify network** → **Advanced**
4. **IP Settings** → **Static** (tạm thời)
5. **DNS 1:** `8.8.8.8` (Google DNS)
6. **DNS 2:** `8.8.4.4`
7. **Save** và thử lại

### **3. Firewall/VPN chặn**

**Giải pháp:**
- ✅ **Tắt VPN** nếu đang bật
- ✅ **Tắt Firewall** tạm thời để test
- ✅ **Thử trên mạng khác** (không phải công ty/school)

### **4. Restart Thiết Bị**

Đôi khi restart thiết bị có thể fix lỗi DNS cache:
1. **Restart điện thoại**
2. **Mở lại app** và thử

---

## 📋 Checklist Nhanh

- [ ] Supabase project đang **Active** (không bị pause) ← **QUAN TRỌNG NHẤT**
- [ ] Thiết bị có internet (WiFi/4G/5G)
- [ ] Đã thử restart app
- [ ] Đã thử restart thiết bị
- [ ] Đã thử mạng khác (WiFi ↔ 4G)
- [ ] Không có VPN/Firewall chặn
- [ ] URL và anon key trong config đúng

---

## 🆘 Nếu Vẫn Không Được

### **Option 1: Kiểm tra lại Config**

1. Mở file `lib/config/supabase_config.dart`
2. Đảm bảo URL đúng: `https://rymvpaazbgdrudsrufam.supabase.co`
3. Kiểm tra anon key có đúng không
4. Rebuild app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### **Option 2: Test với Browser**

Trên điện thoại, mở trình duyệt và truy cập:
```
https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/lessons
```

Nếu thấy JSON response → Server hoạt động tốt, vấn đề ở app code.

### **Option 3: Tạo Project Supabase Mới**

Nếu project cũ có vấn đề:

1. Vào https://app.supabase.com
2. **Create new project**
3. Copy **URL** và **anon key** mới
4. Update vào `lib/config/supabase_config.dart`
5. Chạy lại SQL scripts (`DATABASE_SCHEMA_FIXED.sql`)
6. Rebuild app

---

## 💡 Code đã được cải thiện

Đã thêm error handling tốt hơn trong `supabase_service.dart`:
- Tự động detect lỗi network
- Hiển thị message thân thiện hơn
- Không crash app khi mất kết nối

---

## 📞 Liên Hệ Hỗ Trợ

Nếu vẫn không được:
- Supabase Support: https://supabase.com/support
- Supabase Discord: https://discord.supabase.com






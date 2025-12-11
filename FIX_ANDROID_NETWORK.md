# 🔧 Fix Lỗi Network trên Android - "Failed host lookup"

## ✅ Tin Tốt!

Project Supabase đang **hoạt động tốt**! (Bạn đã test và thấy response từ server)

Vấn đề là **network trên thiết bị Android** không kết nối được.

---

## 🔍 Nguyên Nhân

1. **DNS không resolve được** trên thiết bị Android
2. **Firewall/VPN** chặn kết nối
3. **Network security** settings của Android
4. **WiFi/4G** có vấn đề

---

## ✅ Giải Pháp (Thử theo thứ tự)

### **Giải pháp 1: Đổi DNS trên WiFi (Nhanh nhất)**

1. Vào **Settings** → **WiFi**
2. **Long press** vào WiFi đang dùng
3. Chọn **"Modify network"** hoặc **"Network details"**
4. **Advanced options** → **IP Settings**
5. Đổi từ **"DHCP"** sang **"Static"** (tạm thời)
6. Điền:
   - **DNS 1:** `8.8.8.8` (Google DNS)
   - **DNS 2:** `8.8.4.4`
7. **Save**
8. **Restart app** và thử lại

### **Giải pháp 2: Thử Mạng Khác**

1. **Tắt WiFi**, dùng **4G/5G**
2. Hoặc ngược lại: **Tắt 4G/5G**, dùng **WiFi**
3. **Restart app** và thử lại

### **Giải pháp 3: Tắt VPN/Firewall**

- ✅ **Tắt VPN** nếu đang bật
- ✅ **Tắt Firewall** tạm thời để test
- ✅ **Thử trên mạng khác** (không phải công ty/school)

### **Giải pháp 4: Restart Thiết Bị**

1. **Restart điện thoại**
2. **Mở lại app** và thử

### **Giải pháp 5: Clear App Data**

1. Vào **Settings** → **Apps** → Tìm app của bạn
2. **Storage** → **Clear Data**
3. **Mở lại app** và thử

---

## 🔧 Fix Code (Nếu vẫn không được)

### Thêm Network Security Config

1. **Tạo file:** `android/app/src/main/res/xml/network_security_config.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">rymvpaazbgdrudsrufam.supabase.co</domain>
    </domain-config>
</network-security-config>
```

2. **Update AndroidManifest.xml:**

Thêm vào `<application>` tag:
```xml
<application
    ...
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```

**Lưu ý:** Điều này chỉ cần thiết nếu có vấn đề với HTTPS certificate.

---

## 📋 Checklist Nhanh

- [ ] Đã thử đổi DNS (8.8.8.8, 8.8.4.4)
- [ ] Đã thử mạng khác (WiFi ↔ 4G)
- [ ] Đã tắt VPN/Firewall
- [ ] Đã restart thiết bị
- [ ] Đã clear app data
- [ ] Thiết bị có internet (test browser)

---

## 🆘 Nếu Vẫn Không Được

### Test trên Emulator

1. Chạy app trên **Android Emulator** (có internet)
2. Nếu emulator hoạt động tốt → Vấn đề ở thiết bị thật
3. Nếu emulator cũng lỗi → Vấn đề ở code/config

### Test với Browser trên Thiết Bị

1. Mở **Chrome** trên điện thoại
2. Truy cập: `https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/lessons`
3. Nếu browser cũng không vào được → Vấn đề network của thiết bị
4. Nếu browser vào được → Vấn đề ở app code

### Kiểm tra Logs Chi Tiết

```bash
flutter logs | Select-String "supabase|network|dns|host"
```

Xem có lỗi gì khác không.

---

## 💡 Lưu Ý

- **Project Supabase đang hoạt động tốt** (đã test trên browser)
- Vấn đề chỉ ở **network của thiết bị Android**
- Thử các giải pháp trên theo thứ tự
- Giải pháp 1 (đổi DNS) thường fix được 80% trường hợp






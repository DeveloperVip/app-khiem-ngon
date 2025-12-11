# 🔧 Fix Lỗi Network trên Thiết Bị Thật (Không Có trên Emulator)

## ❌ Vấn Đề:
- ✅ **Emulator:** Chạy bình thường, kết nối Supabase OK
- ❌ **Thiết Bị Thật:** Lỗi "SocketFailed host lookup"

## 🔍 Nguyên Nhân:
**INTERNET permission chỉ có trong debug/profile manifests, nhưng KHÔNG có trong main AndroidManifest.xml!**

Khi build **release APK**, nó không có INTERNET permission → Không thể kết nối mạng trên thiết bị thật.

## ✅ Đã Fix:

Đã thêm vào `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

## 🔄 Bước Tiếp Theo:

### 1. Rebuild APK Release:
```bash
cd flutter_application_initial
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Cài Đặt APK Mới:
- Gỡ app cũ trên thiết bị
- Cài APK mới đã rebuild
- Thử lại

## ✅ Kiểm Tra:

Sau khi cài APK mới, app sẽ có quyền INTERNET và có thể kết nối Supabase.

## 📋 Checklist:

- [x] Đã thêm INTERNET permission vào main AndroidManifest.xml
- [ ] Đã chạy `flutter clean`
- [ ] Đã rebuild APK release
- [ ] Đã gỡ app cũ trên thiết bị
- [ ] Đã cài APK mới
- [ ] Đã test kết nối Supabase

## 🆘 Nếu Vẫn Không Được:

### Kiểm tra trên thiết bị:

1. **Settings** → **Apps** → Tìm app của bạn
2. **Permissions** → Kiểm tra **Internet** có được cấp không
3. Nếu không có → Cấp quyền thủ công

### Kiểm tra Network:

1. **Settings** → **WiFi** hoặc **Mobile Data**
2. Đảm bảo đã bật và có kết nối
3. Thử mở trình duyệt và truy cập google.com

### Test kết nối Supabase:

Trên điện thoại, mở trình duyệt và truy cập:
```
https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/
```

Nếu thấy JSON response → Server OK, vấn đề ở app
Nếu không kết nối được → Vấn đề về network/DNS







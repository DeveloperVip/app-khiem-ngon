# 🔧 Fix Lỗi "No API key found in request"

## ❌ Lỗi:
```
"message":"No API key found in request"
"hint":"No apikey request header or url param was found."
```

## 🔍 Nguyên nhân:
Lỗi này xảy ra khi Supabase client không gửi anon key trong request header. Có thể do:

1. **Anon key không được load đúng khi build release**
2. **Supabase client chưa được khởi tạo đúng cách**
3. **Anon key bị null/empty khi runtime**

## ✅ Cách Fix:

### Bước 1: Kiểm tra Config

1. **Mở file:** `lib/config/supabase_config.dart`
2. **Đảm bảo:**
   ```dart
   static const String supabaseUrl = 'https://rymvpaazbgdrudsrufam.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```
3. **Kiểm tra anon key có đúng không:**
   - Vào Supabase Dashboard: https://app.supabase.com
   - Chọn project → Settings → API
   - Copy **anon/public** key mới
   - Update vào `supabase_config.dart`

### Bước 2: Clean và Rebuild

```bash
cd flutter_application_initial
flutter clean
flutter pub get
flutter build apk --release
```

### Bước 3: Kiểm tra Logs

Sau khi rebuild, khi mở app, kiểm tra logs:
- ✅ Nếu thấy: `✅ Supabase đã được khởi tạo thành công`
- ❌ Nếu thấy: `❌ ERROR: Supabase URL hoặc anon key bị rỗng!`

### Bước 4: Verify Anon Key

**Trên máy tính, mở trình duyệt và test:**

1. **Test với curl:**
```bash
curl -X POST "https://rymvpaazbgdrudsrufam.supabase.co/auth/v1/signup" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123456"}'
```

2. **Nếu thành công** → Anon key đúng, vấn đề ở app
3. **Nếu lỗi** → Kiểm tra lại anon key trong Supabase Dashboard

### Bước 5: Kiểm tra Supabase Project

1. Vào https://app.supabase.com
2. Chọn project `rymvpaazbgdrudsrufam`
3. **Settings** → **API**
4. **Copy lại anon key** (có thể đã thay đổi)
5. Update vào `lib/config/supabase_config.dart`
6. **Rebuild app**

## 🔍 Debug Steps:

### Thêm Debug Logs:

Code đã được thêm debug logs trong `main.dart`:
- Sẽ hiển thị URL và anon key khi khởi tạo
- Sẽ báo lỗi nếu config không hợp lệ

### Kiểm tra Runtime:

1. **Kết nối điện thoại với máy tính**
2. **Chạy:**
   ```bash
   flutter logs
   ```
3. **Mở app** và xem logs:
   - Tìm dòng `📦 Đang khởi tạo Supabase...`
   - Kiểm tra URL và anon key có được log ra không
   - Nếu anon key bị rỗng → Vấn đề ở config

## 🆘 Nếu Vẫn Không Được:

### Option 1: Hardcode Anon Key (Test)

Tạm thời hardcode để test:

```dart
await Supabase.initialize(
  url: 'https://rymvpaazbgdrudsrufam.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5bXZwYWF6YmdkcnVkc3J1ZmFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMDUxNDUsImV4cCI6MjA4MDU4MTE0NX0.o4bm0czb3P0HnLmhciNH2ifhQc_ZdHhZv-20ecFi-rA',
);
```

Nếu hardcode hoạt động → Vấn đề ở cách load config

### Option 2: Kiểm tra Build Config

1. **Mở:** `android/app/build.gradle.kts`
2. **Kiểm tra:** Không có gì strip constants
3. **Đảm bảo:** `minifyEnabled = false` trong debug (hoặc ProGuard rules đúng)

### Option 3: Tạo Project Mới

Nếu vẫn không được, có thể project Supabase có vấn đề:

1. **Tạo project Supabase mới**
2. **Copy URL và anon key mới**
3. **Update config**
4. **Chạy lại SQL scripts**
5. **Rebuild app**

## ✅ Checklist:

- [ ] Anon key trong `supabase_config.dart` đúng và không rỗng
- [ ] Đã chạy `flutter clean` trước khi rebuild
- [ ] Đã rebuild APK sau khi thay đổi config
- [ ] Logs hiển thị Supabase khởi tạo thành công
- [ ] Đã test anon key với curl/Postman
- [ ] Supabase project đang Active (không bị pause)









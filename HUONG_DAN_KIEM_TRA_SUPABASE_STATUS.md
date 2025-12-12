# 📍 Hướng Dẫn Kiểm Tra Status Supabase Project

## 🔍 Cách 1: Kiểm tra trong Dashboard (Dễ nhất)

### Bước 1: Vào Supabase Dashboard
1. Mở trình duyệt (Chrome, Edge, Safari...)
2. Truy cập: **https://app.supabase.com**
3. **Đăng nhập** vào tài khoản

### Bước 2: Tìm Project
1. Sau khi đăng nhập, bạn sẽ thấy danh sách các **Projects**
2. Tìm project có tên hoặc URL chứa: **`rymvpaazbgdrudsrufam`**
3. Hoặc tìm project có URL: **`https://rymvpaazbgdrudsrufam.supabase.co`**

### Bước 3: Kiểm tra Status
**Status sẽ hiển thị ở một trong các vị trí sau:**

#### Vị trí A: Trên card project (trang Projects)
- Nhìn vào **card project** trong danh sách
- Status có thể hiển thị:
  - 🟢 **"Active"** hoặc **"Running"** → Project đang hoạt động
  - 🟡 **"Paused"** hoặc **"Pausing"** → Project bị tạm dừng
  - 🔴 **"Inactive"** → Project không hoạt động

#### Vị trí B: Trong Project Settings
1. **Click vào project** để mở
2. Vào **Settings** (biểu tượng ⚙️ ở sidebar bên trái)
3. Vào **General** hoặc **Project Settings**
4. Tìm phần **"Project Status"** hoặc **"Status"**

#### Vị trí C: Trên thanh header của project
- Khi đã vào trong project, nhìn lên **header** (phía trên)
- Có thể có badge hoặc indicator hiển thị status

---

## 🔍 Cách 2: Kiểm tra qua URL trực tiếp

### Test kết nối Supabase:

**Trên điện thoại hoặc máy tính, mở trình duyệt và truy cập:**

```
https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/
```

**Kết quả:**

#### ✅ Nếu thấy JSON response (ví dụ: `{"message":"..."}`)
→ **Project đang hoạt động tốt!**
→ Vấn đề có thể ở app code hoặc network của thiết bị

#### ❌ Nếu thấy lỗi:
- **"This site can't be reached"**
- **"ERR_NAME_NOT_RESOLVED"**
- **"Failed host lookup"**
→ **Project có thể bị PAUSE hoặc đã bị xóa**

---

## 🔍 Cách 3: Kiểm tra trong Supabase Dashboard - Chi tiết

### Nếu không thấy status rõ ràng:

1. **Vào trang Projects:**
   - https://app.supabase.com/projects
   - Xem danh sách tất cả projects

2. **Tìm project `rymvpaazbgdrudsrufam`**

3. **Nhìn vào các dấu hiệu:**
   - **Nút "Restore"** hoặc **"Resume"** → Project đang bị pause
   - **Nút "Pause"** → Project đang active
   - **Màu xanh** → Active
   - **Màu vàng/cam** → Paused hoặc đang pause
   - **Màu xám** → Inactive hoặc deleted

4. **Nếu thấy nút "Restore" hoặc "Resume":**
   - Click vào nút đó
   - Đợi 1-2 phút
   - Project sẽ được khôi phục

---

## 🎯 Cách Nhanh Nhất: Test trực tiếp

### Trên điện thoại (nơi app đang chạy):

1. **Mở trình duyệt** (Chrome, Safari...)
2. **Truy cập:**
   ```
   https://rymvpaazbgdrudsrufam.supabase.co/rest/v1/lessons
   ```
3. **Kết quả:**
   - ✅ **Thấy JSON data** → Project hoạt động tốt
   - ❌ **Không kết nối được** → Project bị pause hoặc có vấn đề

---

## 📸 Hình ảnh minh họa (mô tả)

### Trang Projects List:
```
┌─────────────────────────────────────┐
│  Projects                            │
├─────────────────────────────────────┤
│  ┌──────────────────────────────┐   │
│  │ Project Name                 │   │
│  │ rymvpaazbgdrudsrufam         │   │
│  │ 🟡 Paused                    │ ← Status ở đây
│  │ [Restore] [Settings]         │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Trong Project Settings:
```
Settings > General
├─ Project Name: rymvpaazbgdrudsrufam
├─ Project URL: https://rymvpaazbgdrudsrufam.supabase.co
├─ Status: 🟡 Paused  ← Status ở đây
└─ [Restore Project] button
```

---

## ⚠️ Lưu Ý Quan Trọng

1. **Free tier tự động pause sau 7 ngày không dùng**
2. **Khi project bị pause:**
   - URL vẫn tồn tại nhưng không thể kết nối
   - Cần click "Restore" để khôi phục
   - Mất 1-2 phút để khởi động lại

3. **Nếu không tìm thấy project:**
   - Có thể project đã bị xóa
   - Hoặc bạn đang đăng nhập sai tài khoản
   - Kiểm tra lại email đăng nhập

---

## 🆘 Nếu Vẫn Không Tìm Thấy

### Option 1: Tạo Project Mới
1. Vào https://app.supabase.com
2. Click **"New Project"**
3. Điền thông tin
4. Copy **URL** và **anon key** mới
5. Update vào `lib/config/supabase_config.dart`

### Option 2: Kiểm tra Email đăng nhập
- Đảm bảo đang đăng nhập đúng tài khoản đã tạo project
- Thử đăng xuất và đăng nhập lại

### Option 3: Liên hệ Support
- Supabase Support: https://supabase.com/support
- Hoặc Discord: https://discord.supabase.com








# Hướng dẫn Cấu hình Camera cho Android Emulator

## Vấn đề
Android Emulator mặc định không có camera thật, nên ứng dụng không thể quay được hình ảnh.

## Giải pháp

### Cách 1: Dùng Webcam máy tính (Khuyến nghị)

1. **Mở Android Emulator**
2. **Vào Extended Controls:**
   - Click vào biểu tượng **⋯** (3 chấm) ở thanh công cụ bên phải emulator
   - Hoặc nhấn `Ctrl + Shift + A` (Windows/Linux) hoặc `Cmd + Shift + A` (Mac)

3. **Cấu hình Camera:**
   - Trong menu bên trái, chọn **Camera**
   - Trong phần **Camera 1 (Front)**, chọn:
     - **Webcam0** - Dùng webcam máy tính (nếu có)
     - **VirtualScene** - Dùng camera ảo (hiển thị cảnh ảo)
   - Trong phần **Camera 2 (Back)**, chọn tương tự

4. **Restart Emulator:**
   - Đóng emulator
   - Mở lại emulator
   - Chạy lại app

### Cách 2: Test trên thiết bị thật (Tốt nhất)

1. **Bật USB Debugging trên điện thoại:**
   - Vào **Settings** > **About phone**
   - Tap **Build number** 7 lần để bật Developer options
   - Vào **Settings** > **Developer options**
   - Bật **USB debugging**

2. **Kết nối điện thoại với máy tính:**
   - Dùng cáp USB
   - Chấp nhận "Allow USB debugging" trên điện thoại

3. **Chạy app trên điện thoại:**
   ```bash
   flutter devices  # Kiểm tra thiết bị
   flutter run      # Chạy app
   ```

### Cách 3: Dùng VirtualScene (Camera ảo)

Nếu không có webcam, có thể dùng VirtualScene:
- Emulator sẽ hiển thị cảnh ảo thay vì camera thật
- Vẫn có thể test được các tính năng của app
- Không quay được hình ảnh thật của bạn

## Kiểm tra Camera đã hoạt động

1. Mở app trên emulator
2. Vào tab **"Dịch Realtime"**
3. Nếu camera hoạt động, bạn sẽ thấy:
   - Preview camera hiển thị
   - Có thể thấy hình ảnh từ webcam hoặc cảnh ảo
   - Có nút "Chụp & Dịch"

## Troubleshooting

### Camera vẫn không hoạt động

1. **Kiểm tra Webcam:**
   - Đảm bảo webcam không bị ứng dụng khác sử dụng
   - Thử mở ứng dụng Camera trên Windows/Mac để kiểm tra webcam

2. **Kiểm tra Permissions:**
   - Trong emulator, vào **Settings** > **Apps** > **Your App** > **Permissions**
   - Đảm bảo Camera permission được cấp

3. **Restart Emulator:**
   - Đóng hoàn toàn emulator
   - Mở lại từ Android Studio
   - Chạy lại app

4. **Kiểm tra Logs:**
   ```bash
   flutter run
   # Xem logs để tìm lỗi camera
   ```

### Lỗi "Camera not available"

- Đảm bảo đã cấu hình camera trong Extended Controls
- Thử chọn camera khác (Webcam0, VirtualScene)
- Restart emulator sau khi thay đổi cấu hình

## Lưu ý

- **VirtualScene** chỉ hiển thị cảnh ảo, không quay được hình ảnh thật
- **Webcam0** sẽ quay được hình ảnh thật từ webcam máy tính
- **Test trên thiết bị thật** là cách tốt nhất để có camera thực tế

## Hình ảnh minh họa

### Extended Controls
```
Android Emulator
├── Location
├── Camera          ← Chọn đây
├── Battery
├── Phone
└── ...
```

### Camera Settings
```
Camera 1 (Front)
├── Webcam0         ← Chọn để dùng webcam
├── VirtualScene    ← Chọn để dùng camera ảo
└── None

Camera 2 (Back)
├── Webcam0
├── VirtualScene
└── None
```









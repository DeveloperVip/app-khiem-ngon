# 📖 Tóm Tắt 2 Chế Độ Translation

## 🎯 Tổng Quan

App có **2 chế độ dịch realtime** được train từ Python, mỗi chế độ phù hợp với mục đích khác nhau:

---

## 🔄 **CHẾ ĐỘ 1: REALTIME CONTINUOUS** 
*(Giống `realtime_demo.py`)*

### 🎬 Cách Hoạt Động:

1. **Bật camera** → Camera quay liên tục (30 frames/giây)

2. **Mỗi frame** → App tự động:
   - Extract keypoints từ hình ảnh (1662 điểm)
   - Lưu vào buffer (giữ 30 frames gần nhất)
   - Tự động xóa frame cũ khi có frame mới

3. **Khi đủ 30 frames** → App tự động:
   - Đưa 30 frames vào model LSTM để predict
   - Tính độ tin cậy (confidence)

4. **Nếu confidence >= 80%** → Hiển thị kết quả ngay trên màn hình
   - Nếu < 80% → Không hiển thị gì (đang chờ thêm frames)

### 📊 Đặc Điểm:

- ✅ **Tự động hoàn toàn** - Không cần nhấn nút
- ✅ **Liên tục** - Phân tích mọi lúc
- ✅ **Threshold cao (80%)** - Chỉ hiển thị khi rất chắc chắn
- ✅ **Phù hợp**: Dịch realtime khi đang nói chuyện, demo

### 🎯 Khi Nào Dùng:

- Khi muốn dịch **liên tục** trong khi đang làm ký hiệu
- Khi muốn xem kết quả **ngay lập tức** trên màn hình
- Khi cần độ chính xác cao (chỉ hiển thị khi chắc chắn 80%)

### 💡 Ví Dụ:

```
Bạn đang làm ký hiệu "Xin chào"
→ Camera quay liên tục
→ App tự động phân tích
→ Khi đủ 30 frames và confidence >= 80%
→ Hiển thị "Xin chào" trên màn hình
→ Tiếp tục phân tích frames tiếp theo...
```

---

## 📚 **CHẾ ĐỘ 2: DICTIONARY MODE**
*(Giống `dictionary_mode.py`)*

### 🎬 Cách Hoạt Động:

1. **Nhấn nút "Ghi"** → App bắt đầu ghi đúng 30 frames liên tiếp

2. **Trong khi ghi** → Bạn thực hiện ký hiệu (ví dụ: "Cảm ơn")
   - App hiển thị counter: 1/30, 2/30, ..., 30/30
   - Mỗi frame được lưu lại

3. **Sau khi ghi xong 30 frames** → App tự động:
   - Dừng ghi
   - Extract keypoints từ 30 frames
   - Đưa vào model LSTM để predict
   - Tính độ tin cậy

4. **Hiển thị kết quả trong dialog**:
   - Nếu confidence >= 60% → Hiển thị kết quả (ví dụ: "Cảm ơn")
   - Nếu confidence < 60% → Hiển thị "Thao tác ngôn ngữ ký hiệu không được tìm thấy"

### 📊 Đặc Điểm:

- ✅ **Manual trigger** - Phải nhấn nút để bắt đầu
- ✅ **Ghi đúng 30 frames** - Không tự động, phải ghi đủ
- ✅ **Threshold thấp hơn (60%)** - Dễ hiển thị kết quả hơn
- ✅ **Dialog kết quả** - Hiển thị trong popup, không phải overlay
- ✅ **Phù hợp**: Tra cứu từ điển, kiểm tra ký hiệu cụ thể

### 🎯 Khi Nào Dùng:

- Khi muốn **tra cứu** một ký hiệu cụ thể
- Khi muốn **kiểm tra** xem ký hiệu có đúng không
- Khi muốn **lưu lại** kết quả dịch
- Khi cần kết quả **rõ ràng** trong dialog

### 💡 Ví Dụ:

```
Bạn muốn tra cứu ký hiệu "Xin lỗi"
→ Nhấn nút "Ghi"
→ Thực hiện ký hiệu "Xin lỗi" trong khi đang ghi
→ App ghi đúng 30 frames
→ Sau khi ghi xong → Dialog hiển thị "Xin lỗi" (nếu confidence >= 60%)
→ Hoặc "Thao tác ngôn ngữ ký hiệu không được tìm thấy" (nếu < 60%)
```

---

## 🔍 So Sánh 2 Chế Độ

| Tiêu Chí | **Realtime Mode** | **Dictionary Mode** |
|----------|-------------------|----------------------|
| **Cách kích hoạt** | Tự động | Nhấn nút "Ghi" |
| **Threshold** | 80% (cao) | 60% (thấp hơn) |
| **Hiển thị** | Overlay trên camera | Dialog popup |
| **Tốc độ** | Liên tục, realtime | Chờ ghi xong 30 frames |
| **Độ chính xác** | Cao hơn (chỉ hiển thị khi rất chắc) | Thấp hơn (dễ hiển thị hơn) |
| **Use case** | Dịch khi đang nói chuyện | Tra cứu từ điển |
| **Python file** | `realtime_demo.py` | `dictionary_mode.py` |

---

## 🎨 Giao Diện

### **Realtime Mode:**
```
┌─────────────────────────┐
│  [Realtime] Dictionary  │ ← Mode selector
│                         │
│     📹 Camera View      │
│                         │
│  ┌───────────────────┐ │
│  │ Kết quả dịch:     │ │ ← Overlay
│  │ Xin chào (85%)    │ │
│  └───────────────────┘ │
│                         │
│  [🔄] [▶️]              │ ← Controls
│                         │
│  Realtime: Đang phân   │
│  tích liên tục...      │
└─────────────────────────┘
```

### **Dictionary Mode:**
```
┌─────────────────────────┐
│  Realtime [Dictionary]  │ ← Mode selector
│                         │
│     📹 Camera View      │
│                         │
│  [🔄] [🔴 15/30]         │ ← Recording button
│                         │
│  Dictionary: Nhấn nút  │
│  để ghi 30 frames...    │
│                         │
│  ┌───────────────────┐ │
│  │ Kết quả dịch:     │ │ ← Dialog (sau khi ghi)
│  │ Cảm ơn (75%)      │ │
│  │ [Đóng] [Lưu]      │ │
│  └───────────────────┘ │
└─────────────────────────┘
```

---

## 🔄 Luồng Xử Lý

### **Realtime Mode Flow:**

```
Camera Stream (30fps)
    ↓
Frame 1 → Extract keypoints → Buffer[Frame1]
Frame 2 → Extract keypoints → Buffer[Frame1, Frame2]
...
Frame 30 → Extract keypoints → Buffer[Frame1...Frame30]
    ↓
Đủ 30 frames → Predict
    ↓
Confidence >= 80%? 
    ├─ YES → Hiển thị trên overlay
    └─ NO → Không hiển thị, tiếp tục
    ↓
Frame 31 → Extract keypoints → Buffer[Frame2...Frame31] (xóa Frame1)
    ↓
Lặp lại...
```

### **Dictionary Mode Flow:**

```
User nhấn nút "Ghi"
    ↓
Bắt đầu ghi frames
    ↓
Frame 1 → Extract keypoints → Save[Frame1]
Frame 2 → Extract keypoints → Save[Frame2]
...
Frame 30 → Extract keypoints → Save[Frame30]
    ↓
Dừng ghi
    ↓
Predict với 30 frames đã ghi
    ↓
Confidence >= 60%?
    ├─ YES → Hiển thị kết quả trong dialog
    └─ NO → Hiển thị "Không tìm thấy"
```

---

## 💡 Tại Sao 2 Chế Độ?

### **Realtime Mode (80%):**
- **Mục đích**: Dịch liên tục khi đang giao tiếp
- **Threshold cao** để tránh hiển thị sai
- **Tự động** để không làm gián đoạn cuộc trò chuyện

### **Dictionary Mode (60%):**
- **Mục đích**: Tra cứu ký hiệu cụ thể
- **Threshold thấp hơn** để dễ tìm thấy ký hiệu
- **Manual** để user có thể chuẩn bị và thực hiện đúng ký hiệu

---

## 🎯 Kết Luận

- **Realtime Mode**: Giống như **dịch realtime** khi đang nói chuyện - tự động, liên tục, độ chính xác cao
- **Dictionary Mode**: Giống như **tra từ điển** - nhấn nút, ghi lại, xem kết quả

Cả 2 chế độ đều dùng **cùng 1 model LSTM** đã train, chỉ khác cách sử dụng và threshold!









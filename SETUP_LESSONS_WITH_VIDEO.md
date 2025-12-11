# Hướng dẫn Setup Lessons với Video

## ✅ Đã hoàn thành

1. ✅ Model đã hỗ trợ `videoUrl` trong:
   - `LessonContent` (nội dung bài học)
   - `QuizQuestion` (câu hỏi kiểm tra)

2. ✅ UI đã hiển thị video:
   - **Lesson Detail Screen**: Video phía trên, translation phía dưới
   - **Quiz Screen**: Video phía trên, câu hỏi và đáp án phía dưới

3. ✅ Script tạo dữ liệu đã sẵn sàng

## 📋 Các bước setup

### Bước 1: Upload Video lên Supabase Storage

1. Vào **Supabase Dashboard** > **Storage**
2. Tạo bucket mới tên `lessons` (hoặc dùng bucket `user_media`)
3. Upload các video:
   - `xin_chao.mp4` - Video cách làm ký hiệu "Xin chào"
   - `cam_on.mp4` - Video cách làm ký hiệu "Cảm ơn"
   - `xin_loi.mp4` - Video cách làm ký hiệu "Xin lỗi"
4. Sau khi upload, click vào từng file để xem chi tiết
5. Copy **Public URL** của mỗi video

**Ví dụ Public URL:**
```
https://xxxxx.supabase.co/storage/v1/object/public/lessons/xin_chao.mp4
```

### Bước 2: Cập nhật SQL với Video URLs

1. Mở file `Sign-language-dictionary-with-machine-learning/lessons_insert_template.sql`
2. Thay thế tất cả `YOUR_SUPABASE_STORAGE_URL/xxx.mp4` bằng Public URLs thực tế

**Ví dụ:**
```sql
-- Thay vì:
"video_url": "YOUR_SUPABASE_STORAGE_URL/xin_chao.mp4"

-- Thay bằng:
"video_url": "https://xxxxx.supabase.co/storage/v1/object/public/lessons/xin_chao.mp4"
```

### Bước 3: Chạy SQL trong Supabase

1. Vào **Supabase Dashboard** > **SQL Editor**
2. Copy toàn bộ nội dung từ file `lessons_insert_template.sql` (sau khi đã thay URLs)
3. Click **Run** để chạy
4. Kiểm tra kết quả trong **Table Editor** > `lessons`

### Bước 4: Kiểm tra trong App

1. Chạy app: `flutter run`
2. Vào tab **Bài học**
3. Click vào một bài học
4. Kiểm tra:
   - ✅ Video hiển thị phía trên
   - ✅ Translation hiển thị phía dưới
   - ✅ Có thể play/pause video
5. Vào **Bài kiểm tra**:
   - ✅ Video hiển thị phía trên câu hỏi
   - ✅ Các đáp án hiển thị phía dưới
   - ✅ Có thể chọn đáp án

## 📝 Cấu trúc dữ liệu

### Lesson Content
```json
{
  "id": "content_xin_chao_1",
  "type": "video",
  "video_url": "https://...",  // URL video từ Supabase Storage
  "translation": "Xin chào",
  "description": "Cách làm ký hiệu 'Xin chào'",
  "order": 0
}
```

### Quiz Question
```json
{
  "id": "q_xin_chao_1",
  "question": "Ký hiệu trong video trên có nghĩa là gì?",
  "video_url": "https://...",  // URL video từ Supabase Storage (có thể dùng cùng video với content)
  "options": ["Xin chào", "Tạm biệt", "Cảm ơn", "Xin lỗi"],
  "correct_answer_index": 0,
  "explanation": "Đây là cách làm ký hiệu 'Xin chào'"
}
```

## 🎯 Lưu ý quan trọng

1. **Video URLs phải là Public URLs** từ Supabase Storage
2. **Có thể dùng cùng một video** cho cả content và quiz question
3. **Video phải ở định dạng hỗ trợ** (mp4, webm, etc.)
4. **Đảm bảo bucket có policy public** để video có thể truy cập được

## 🔧 Troubleshooting

### Video không hiển thị
- Kiểm tra URL có đúng không
- Kiểm tra bucket có policy public không
- Kiểm tra video có tồn tại trong Storage không

### Video không play được
- Kiểm tra định dạng video (nên dùng mp4)
- Kiểm tra kết nối internet
- Kiểm tra console logs để xem lỗi

### Quiz không có video
- Đảm bảo `video_url` trong quiz question không null
- Kiểm tra JSON structure có đúng không

## 📞 Hỗ trợ

Nếu gặp vấn đề, kiểm tra:
1. File `lessons_insert_template.sql` đã được cập nhật URLs chưa
2. SQL đã chạy thành công trong Supabase chưa
3. Data trong table `lessons` có đúng format không







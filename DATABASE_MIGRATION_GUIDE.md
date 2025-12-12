# Hướng dẫn Migration Database - Từ JSONB sang Normalized

## 🎯 Mục tiêu

Thiết kế lại database từ cấu trúc JSONB sang normalized (tách riêng các bảng) để:
- ✅ Dễ query và filter
- ✅ Performance tốt hơn
- ✅ Dễ maintain và scale
- ✅ Dễ thêm/sửa/xóa contents và questions

## 📊 Cấu trúc Database Mới

### Các bảng:

1. **`lessons`** - Bài học
   - `id`, `title`, `description`, `order`, `thumbnail_url`, `estimated_duration`

2. **`lesson_contents`** - Nội dung bài học (tách riêng)
   - `id`, `lesson_id`, `content_type`, `video_url`, `image_url`, `translation`, `description`, `order`

3. **`quizzes`** - Bài kiểm tra (tách riêng)
   - `id`, `lesson_id`

4. **`quiz_questions`** - Câu hỏi quiz (tách riêng)
   - `id`, `quiz_id`, `question`, `video_url`, `correct_answer_index`, `explanation`, `order`

5. **`quiz_options`** - Đáp án của câu hỏi (tách riêng)
   - `id`, `question_id`, `option_text`, `order`

## 🚀 Các bước Migration

### Bước 1: Tạo Schema Mới

1. Vào **Supabase Dashboard** > **SQL Editor**
2. Copy toàn bộ nội dung từ file `DATABASE_SCHEMA_NEW.sql`
3. Chạy SQL để tạo các bảng mới

**Lưu ý**: Các bảng cũ (`lessons` với JSONB) vẫn còn, không bị xóa.

### Bước 2: Insert Dữ liệu Mẫu

1. Vào **SQL Editor**
2. Copy toàn bộ nội dung từ file `lessons_insert_normalized_fixed.sql`
3. Chạy SQL để insert dữ liệu vào các bảng mới

### Bước 3: Migration Dữ liệu Cũ (Nếu có)

Nếu bạn đã có dữ liệu trong bảng `lessons` cũ (với JSONB), chạy migration script trong `DATABASE_SCHEMA_NEW.sql` (phần comment) để chuyển dữ liệu sang cấu trúc mới.

### Bước 4: Cập nhật Flutter Code

Code Flutter đã được cập nhật trong `supabase_service.dart` để query từ các bảng mới. Không cần thay đổi gì thêm!

### Bước 5: Test

1. Chạy app: `flutter run`
2. Vào tab **"Bài học"**
3. Kiểm tra:
   - ✅ Lessons hiển thị đúng
   - ✅ Mỗi lesson có nhiều contents
   - ✅ Mỗi content có video và translation riêng
   - ✅ Quiz có video và options đúng

## 📝 So sánh Cấu trúc

### Cũ (JSONB):
```sql
lessons
├── contents: JSONB [{"id": "...", "video_url": "...", "translation": "..."}]
└── quiz: JSONB {"questions": [{"options": [...]}]}
```

### Mới (Normalized):
```sql
lessons
├── lesson_contents (1-n)
│   ├── video_url
│   ├── translation
│   └── order
└── quizzes (1-1)
    └── quiz_questions (1-n)
        ├── video_url
        ├── question
        └── quiz_options (1-n)
            └── option_text
```

## ✅ Lợi ích

1. **Query dễ dàng hơn**: Có thể filter contents theo video_url, translation, etc.
2. **Performance tốt hơn**: Index trên các cột riêng
3. **Dễ maintain**: Thêm/sửa/xóa content không cần update cả JSON
4. **Scale tốt hơn**: Có thể thêm metadata cho content/question dễ dàng

## 🔄 Rollback (Nếu cần)

Nếu muốn quay lại cấu trúc cũ:
- Giữ nguyên bảng `lessons` cũ (nếu chưa xóa)
- Không cần làm gì, code Flutter vẫn hoạt động với cả 2 cấu trúc

## 📞 Troubleshooting

### Lỗi Foreign Key
- Đảm bảo đã chạy `DATABASE_SCHEMA_NEW.sql` trước
- Kiểm tra các bảng đã được tạo chưa

### Không thấy dữ liệu
- Kiểm tra SQL đã chạy thành công chưa
- Kiểm tra RLS policies có đúng không
- Xem logs trong Supabase

### Flutter không load được
- Đảm bảo đã cập nhật `supabase_service.dart`
- Kiểm tra console logs để xem lỗi cụ thể









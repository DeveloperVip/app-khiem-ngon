# Hướng dẫn thiết lập Supabase

## Bước 1: Lấy Supabase Credentials

1. Truy cập [Supabase Dashboard](https://app.supabase.com/)
2. Chọn project của bạn (hoặc tạo project mới)
3. Vào **Settings** > **API**
4. Copy các thông tin sau:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Bước 2: Cấu hình trong App

Mở file `lib/config/supabase_config.dart` và thay thế:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Bằng thông tin thực tế của bạn:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

## Bước 3: Tạo Database Schema

Vào **SQL Editor** trong Supabase Dashboard và chạy các script sau:

### 3.1. Tạo bảng `users`

```sql
-- Bảng users (sẽ tự động tạo khi user đăng ký qua Auth)
-- Nhưng cần tạo để lưu thông tin bổ sung
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  total_uploads INTEGER DEFAULT 0,
  total_storage_used BIGINT DEFAULT 0,
  preferences JSONB
);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Users chỉ có thể đọc/update chính mình
CREATE POLICY "Users can view own data"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own data"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own data"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);
```

### 3.2. Tạo bảng `lessons`

```sql
CREATE TABLE IF NOT EXISTS public.lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  "order" INTEGER NOT NULL,
  contents JSONB NOT NULL DEFAULT '[]'::jsonb,
  quiz JSONB,
  thumbnail_url TEXT,
  estimated_duration INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;

-- Policy: Tất cả users đều có thể đọc lessons
CREATE POLICY "Lessons are viewable by everyone"
  ON public.lessons FOR SELECT
  USING (true);
```

### 3.3. Tạo bảng `user_uploads`

```sql
CREATE TABLE IF NOT EXISTS public.user_uploads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  video_url TEXT,
  image_url TEXT,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  translation TEXT,
  confidence DOUBLE PRECISION,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  file_size BIGINT DEFAULT 0,
  file_name TEXT
);

-- Enable Row Level Security
ALTER TABLE public.user_uploads ENABLE ROW LEVEL SECURITY;

-- Policy: Users chỉ có thể xem/upload/delete uploads của chính mình
CREATE POLICY "Users can view own uploads"
  ON public.user_uploads FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own uploads"
  ON public.user_uploads FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own uploads"
  ON public.user_uploads FOR DELETE
  USING (auth.uid() = user_id);
```

### 3.4. Tạo bảng `user_progress`

```sql
CREATE TABLE IF NOT EXISTS public.user_progress (
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
  completed BOOLEAN DEFAULT false,
  current_content_index INTEGER DEFAULT 0,
  completed_at TIMESTAMPTZ,
  quiz_result JSONB,
  PRIMARY KEY (user_id, lesson_id)
);

-- Enable Row Level Security
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- Policy: Users chỉ có thể xem/update progress của chính mình
CREATE POLICY "Users can view own progress"
  ON public.user_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON public.user_progress FOR ALL
  USING (auth.uid() = user_id);
```

## Bước 4: Tạo Storage Bucket

### 4.1. Tạo Bucket

1. Vào **Storage** trong Supabase Dashboard (menu bên trái)
2. Click nút **New bucket** hoặc **Create bucket**
3. Đặt tên: `user_media`
4. Set **Public bucket**: OFF (tắt - để bucket là private)
5. Click **Create bucket**

### 4.2. Thêm Storage Policies

Sau khi tạo bucket, bạn cần thêm policies để kiểm soát quyền truy cập. Có 2 cách:

#### Cách 1: Sử dụng SQL Editor (Khuyến nghị)

1. Vào **SQL Editor** trong Supabase Dashboard (menu bên trái)
2. Click **New query**
3. Copy và paste đoạn SQL sau vào editor:

```sql
-- Policy: Users có thể upload vào thư mục của mình
CREATE POLICY "Users can upload own files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'user_media' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: Users có thể xem files của mình
CREATE POLICY "Users can view own files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'user_media' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy: Users có thể xóa files của mình
CREATE POLICY "Users can delete own files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'user_media' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );
```

4. Click nút **Run** (hoặc nhấn Ctrl+Enter) để chạy SQL
5. Kiểm tra kết quả - nếu thành công sẽ thấy message "Success"

#### Cách 2: Sử dụng Storage Policies UI

1. Vào **Storage** > chọn bucket `user_media`
2. Click tab **Policies** ở trên cùng
3. Click **New Policy**
4. Chọn loại policy:
   - **INSERT**: Cho phép upload
   - **SELECT**: Cho phép xem/download
   - **DELETE**: Cho phép xóa
5. Đặt tên policy (ví dụ: "Users can upload own files")
6. Trong phần **Policy definition**, chọn **Custom policy**
7. Paste policy expression tương ứng:

**Cho INSERT:**
```sql
bucket_id = 'user_media' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Cho SELECT:**
```sql
bucket_id = 'user_media' AND (storage.foldername(name))[1] = auth.uid()::text
```

**Cho DELETE:**
```sql
bucket_id = 'user_media' AND (storage.foldername(name))[1] = auth.uid()::text
```

8. Click **Review** và sau đó **Save policy**

**Lưu ý:** Cách 1 (SQL Editor) nhanh hơn và chính xác hơn. Khuyến nghị dùng cách này.

## Bước 5: Tạo Function để Update User Storage (Optional)

Vào **Database** > **Functions** và tạo function:

```sql
CREATE OR REPLACE FUNCTION update_user_storage(
  user_id UUID,
  file_size BIGINT,
  upload_count INTEGER
)
RETURNS void AS $$
BEGIN
  UPDATE public.users
  SET 
    total_uploads = total_uploads + upload_count,
    total_storage_used = total_storage_used + file_size
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Bước 6: Tạo dữ liệu mẫu Lessons

Có 2 cách để thêm dữ liệu mẫu:

### Cách 1: Sử dụng SQL Editor (Khuyến nghị)

1. Vào **SQL Editor** trong Supabase Dashboard
2. Click **New query**
3. Copy và paste đoạn SQL sau:

```sql
-- Thêm bài học mẫu
-- Lưu ý: Thay thế các URL (https://example.com/...) bằng URL thực tế của bạn
INSERT INTO public.lessons (title, description, "order", estimated_duration, thumbnail_url, contents, quiz)
VALUES (
  'Bài học 1: Chào hỏi',
  'Học cách chào hỏi bằng ngôn ngữ ký hiệu',
  1,
  10,
  'https://example.com/thumbnail.jpg',
  '[
    {
      "id": "content1",
      "type": "video",
      "video_url": "https://example.com/video1.mp4",
      "translation": "Xin chào",
      "description": "Cách chào hỏi cơ bản",
      "order": 0
    },
    {
      "id": "content2",
      "type": "image",
      "image_url": "https://example.com/image1.jpg",
      "translation": "Tạm biệt",
      "description": "Cách nói tạm biệt",
      "order": 1
    }
  ]'::jsonb,
  '{
    "id": "quiz1",
    "lesson_id": "",
    "questions": [
      {
        "id": "q1",
        "question": "Cách chào hỏi là gì?",
        "options": ["Xin chào", "Tạm biệt", "Cảm ơn", "Xin lỗi"],
        "correct_answer_index": 0,
        "explanation": "Xin chào là cách chào hỏi cơ bản"
      },
      {
        "id": "q2",
        "question": "Cách nói tạm biệt là gì?",
        "options": ["Xin chào", "Tạm biệt", "Cảm ơn", "Xin lỗi"],
        "correct_answer_index": 1,
        "explanation": "Tạm biệt được dùng khi chia tay"
      }
    ]
  }'::jsonb
);

-- Thêm bài học thứ 2 (nếu muốn)
INSERT INTO public.lessons (title, description, "order", estimated_duration, contents)
VALUES (
  'Bài học 2: Gia đình',
  'Học các từ vựng về gia đình',
  2,
  15,
  '[
    {
      "id": "content3",
      "type": "video",
      "video_url": "https://example.com/video2.mp4",
      "translation": "Bố",
      "description": "Cách ký hiệu từ Bố",
      "order": 0
    },
    {
      "id": "content4",
      "type": "video",
      "video_url": "https://example.com/video3.mp4",
      "translation": "Mẹ",
      "description": "Cách ký hiệu từ Mẹ",
      "order": 1
    }
  ]'::jsonb
);
```

4. Click **Run** để chạy SQL
5. Kiểm tra kết quả - nếu thành công sẽ thấy message "Success"

**Lưu ý:** 
- Thay thế các URL (`https://example.com/...`) bằng URL thực tế của video/ảnh của bạn
- Có thể upload video/ảnh lên Supabase Storage và lấy URL từ đó
- Có thể thêm nhiều bài học bằng cách chạy nhiều câu INSERT

### Cách 2: Sử dụng Table Editor (UI)

1. Vào **Table Editor** trong Supabase Dashboard
2. Chọn bảng `lessons` từ danh sách bên trái
3. Click nút **Insert** > **Insert row**
4. Điền các trường:
   - **title**: `Bài học 1: Chào hỏi`
   - **description**: `Học cách chào hỏi bằng ngôn ngữ ký hiệu`
   - **order**: `1`
   - **estimated_duration**: `10`
   - **thumbnail_url**: `https://example.com/thumbnail.jpg`
   - **contents**: Click vào ô và chọn **JSON Editor**, paste JSON:
   ```json
   [
     {
       "id": "content1",
       "type": "video",
       "video_url": "https://example.com/video1.mp4",
       "translation": "Xin chào",
       "description": "Cách chào hỏi cơ bản",
       "order": 0
     }
   ]
   ```
   - **quiz**: Click vào ô và chọn **JSON Editor**, paste JSON:
   ```json
   {
     "id": "quiz1",
     "lesson_id": "",
     "questions": [
       {
         "id": "q1",
         "question": "Cách chào hỏi là gì?",
         "options": ["Xin chào", "Tạm biệt", "Cảm ơn", "Xin lỗi"],
         "correct_answer_index": 0,
         "explanation": "Xin chào là cách chào hỏi cơ bản"
       }
     ]
   }
   ```
5. Click **Save** để lưu

**Lưu ý:** Cách 1 (SQL Editor) nhanh hơn và dễ copy/paste hơn. Khuyến nghị dùng cách này.

### Upload Media lên Supabase Storage (Tùy chọn)

Nếu bạn muốn upload video/ảnh lên Supabase Storage:

1. Vào **Storage** > bucket `user_media` (hoặc tạo bucket mới cho lessons)
2. Click **Upload file**
3. Chọn file video/ảnh của bạn
4. Sau khi upload, click vào file để xem chi tiết
5. Copy **Public URL** hoặc **Signed URL**
6. Sử dụng URL này trong JSON data của lesson

**Ví dụ cấu trúc bucket cho lessons:**
- Tạo bucket mới tên `lesson_media` (public)
- Upload files vào: `lesson_media/videos/video1.mp4`
- Lấy URL và dùng trong JSON

## Bước 7: Cấu hình Authentication

1. Vào **Authentication** > **Providers**
2. Bật **Email** provider
3. Cấu hình email templates nếu cần

### 7.1. Cấu hình SMTP (Khuyến nghị)

Để tránh rate limit và gửi email tốt hơn, bạn nên cấu hình SMTP riêng:

**Cách nhanh nhất - Dùng Gmail**:
1. Vào **Settings** > **Auth** > **SMTP Settings**
2. Tạo App Password cho Gmail:
   - Vào [Google Account](https://myaccount.google.com/) > Security
   - Bật 2-Step Verification
   - Tạo App Password (chọn Mail)
3. Điền vào Supabase:
   ```
   Sender email: your-email@gmail.com
   Sender name: Ứng dụng Dịch Ngôn Ngữ Ký Hiệu
   Host: smtp.gmail.com
   Port: 587
   Username: your-email@gmail.com
   Password: [App Password 16 ký tự]
   ```
4. Click **Save**

**Xem hướng dẫn chi tiết**: Xem file `SUPABASE_SMTP_SETUP.md` để biết cách setup với các nhà cung cấp khác (SendGrid, Resend, Mailgun...)

## Bước 8: Chạy ứng dụng

```bash
flutter pub get
flutter run
```

## Lưu ý

- Đảm bảo đã cấu hình đúng URL và anon key
- Kiểm tra RLS policies đã được enable
- Storage bucket phải được tạo và có policies phù hợp
- Database schema phải khớp với models trong code

## Troubleshooting

- Nếu gặp lỗi RLS: Kiểm tra policies đã được tạo đúng
- Nếu không upload được: Kiểm tra storage bucket và policies
- Nếu không đọc được data: Kiểm tra RLS policies cho SELECT


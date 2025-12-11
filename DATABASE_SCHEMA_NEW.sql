-- ============================================
-- THIẾT KẾ LẠI DATABASE - CẤU TRÚC NORMALIZED
-- ============================================
-- Thay vì dùng JSONB, tách riêng thành các bảng
-- Giúp dễ query, maintain và scale hơn
-- ============================================

-- ============================================
-- 1. BẢNG LESSONS (Bài học)
-- ============================================
CREATE TABLE IF NOT EXISTS public.lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  "order" INTEGER NOT NULL UNIQUE,
  thumbnail_url TEXT,
  estimated_duration INTEGER DEFAULT 0, -- phút
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index để query nhanh hơn
CREATE INDEX IF NOT EXISTS idx_lessons_order ON public.lessons("order");

-- ============================================
-- 2. BẢNG LESSON_CONTENTS (Nội dung bài học)
-- ============================================
CREATE TABLE IF NOT EXISTS public.lesson_contents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE NOT NULL,
  content_type TEXT NOT NULL CHECK (content_type IN ('video', 'image')),
  video_url TEXT,
  image_url TEXT,
  translation TEXT NOT NULL,
  description TEXT,
  "order" INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Đảm bảo mỗi lesson không có order trùng lặp
  UNIQUE(lesson_id, "order")
);

-- Index để query nhanh hơn
CREATE INDEX IF NOT EXISTS idx_lesson_contents_lesson_id ON public.lesson_contents(lesson_id);
CREATE INDEX IF NOT EXISTS idx_lesson_contents_order ON public.lesson_contents(lesson_id, "order");

-- ============================================
-- 3. BẢNG QUIZZES (Bài kiểm tra)
-- ============================================
CREATE TABLE IF NOT EXISTS public.quizzes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_quizzes_lesson_id ON public.quizzes(lesson_id);

-- ============================================
-- 4. BẢNG QUIZ_QUESTIONS (Câu hỏi quiz)
-- ============================================
CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id UUID REFERENCES public.quizzes(id) ON DELETE CASCADE NOT NULL,
  question TEXT NOT NULL,
  video_url TEXT,
  correct_answer_index INTEGER NOT NULL,
  explanation TEXT,
  "order" INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Đảm bảo mỗi quiz không có order trùng lặp
  UNIQUE(quiz_id, "order")
);

-- Index
CREATE INDEX IF NOT EXISTS idx_quiz_questions_quiz_id ON public.quiz_questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_questions_order ON public.quiz_questions(quiz_id, "order");

-- ============================================
-- 5. BẢNG QUIZ_OPTIONS (Đáp án của câu hỏi)
-- ============================================
CREATE TABLE IF NOT EXISTS public.quiz_options (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  question_id UUID REFERENCES public.quiz_questions(id) ON DELETE CASCADE NOT NULL,
  option_text TEXT NOT NULL,
  "order" INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Đảm bảo mỗi question không có order trùng lặp
  UNIQUE(question_id, "order")
);

-- Index
CREATE INDEX IF NOT EXISTS idx_quiz_options_question_id ON public.quiz_options(question_id);
CREATE INDEX IF NOT EXISTS idx_quiz_options_order ON public.quiz_options(question_id, "order");

-- ============================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================

-- Lessons: Tất cả users đều có thể đọc
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lessons are viewable by everyone"
  ON public.lessons FOR SELECT
  USING (true);

-- Lesson Contents: Tất cả users đều có thể đọc
ALTER TABLE public.lesson_contents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Lesson contents are viewable by everyone"
  ON public.lesson_contents FOR SELECT
  USING (true);

-- Quizzes: Tất cả users đều có thể đọc
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Quizzes are viewable by everyone"
  ON public.quizzes FOR SELECT
  USING (true);

-- Quiz Questions: Tất cả users đều có thể đọc
ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Quiz questions are viewable by everyone"
  ON public.quiz_questions FOR SELECT
  USING (true);

-- Quiz Options: Tất cả users đều có thể đọc
ALTER TABLE public.quiz_options ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Quiz options are viewable by everyone"
  ON public.quiz_options FOR SELECT
  USING (true);

-- ============================================
-- 7. FUNCTIONS & TRIGGERS (Optional)
-- ============================================

-- Function để tự động update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger cho lessons
CREATE TRIGGER update_lessons_updated_at
  BEFORE UPDATE ON public.lessons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. VIEWS (Để query dễ dàng hơn)
-- ============================================

-- View để lấy lesson với contents và quiz
CREATE OR REPLACE VIEW public.lessons_with_contents AS
SELECT 
  l.id,
  l.title,
  l.description,
  l."order",
  l.thumbnail_url,
  l.estimated_duration,
  l.created_at,
  l.updated_at,
  -- Aggregate contents thành JSON array (sửa ORDER BY)
  COALESCE(
    json_agg(
      jsonb_build_object(
        'id', lc.id,
        'type', lc.content_type,
        'videoUrl', lc.video_url,
        'imageUrl', lc.image_url,
        'translation', lc.translation,
        'description', lc.description,
        'order', lc."order"
      ) ORDER BY lc."order"
    ) FILTER (WHERE lc.id IS NOT NULL),
    '[]'::json
  ) as contents,
  -- Quiz info
  CASE WHEN q.id IS NOT NULL THEN
    jsonb_build_object(
      'id', q.id,
      'lessonId', q.lesson_id
    )
  ELSE NULL END as quiz
FROM public.lessons l
LEFT JOIN public.lesson_contents lc ON l.id = lc.lesson_id
LEFT JOIN public.quizzes q ON l.id = q.lesson_id
GROUP BY l.id, q.id, q.lesson_id;

-- ============================================
-- 9. MIGRATION SCRIPT (Nếu đã có dữ liệu cũ)
-- ============================================

-- Nếu bạn đã có dữ liệu trong bảng lessons cũ (với JSONB),
-- chạy script migration này để chuyển sang cấu trúc mới:

/*
-- Migration từ JSONB sang normalized tables
DO $$
DECLARE
  lesson_record RECORD;
  content_item JSONB;
  quiz_item JSONB;
  question_item JSONB;
  option_item TEXT;
  new_quiz_id UUID;
  content_order INTEGER;
  question_order INTEGER;
  option_order INTEGER;
BEGIN
  -- Duyệt qua tất cả lessons cũ
  FOR lesson_record IN SELECT * FROM public.lessons WHERE contents IS NOT NULL LOOP
    -- Migrate contents
    IF lesson_record.contents IS NOT NULL THEN
      content_order := 0;
      FOR content_item IN SELECT * FROM jsonb_array_elements(lesson_record.contents) LOOP
        INSERT INTO public.lesson_contents (
          lesson_id,
          content_type,
          video_url,
          image_url,
          translation,
          description,
          "order"
        ) VALUES (
          lesson_record.id,
          content_item->>'type',
          content_item->>'videoUrl',
          content_item->>'imageUrl',
          content_item->>'translation',
          content_item->>'description',
          content_order
        );
        content_order := content_order + 1;
      END LOOP;
    END IF;
    
    -- Migrate quiz
    IF lesson_record.quiz IS NOT NULL THEN
      quiz_item := lesson_record.quiz;
      
      -- Tạo quiz
      INSERT INTO public.quizzes (lesson_id)
      VALUES (lesson_record.id)
      RETURNING id INTO new_quiz_id;
      
      -- Migrate questions
      IF quiz_item->'questions' IS NOT NULL THEN
        question_order := 0;
        FOR question_item IN SELECT * FROM jsonb_array_elements(quiz_item->'questions') LOOP
          DECLARE
            new_question_id UUID;
          BEGIN
            -- Insert question
            INSERT INTO public.quiz_questions (
              quiz_id,
              question,
              video_url,
              correct_answer_index,
              explanation,
              "order"
            ) VALUES (
              new_quiz_id,
              question_item->>'question',
              question_item->>'videoUrl',
              (question_item->>'correctAnswerIndex')::INTEGER,
              question_item->>'explanation',
              question_order
            ) RETURNING id INTO new_question_id;
            
            -- Insert options
            IF question_item->'options' IS NOT NULL THEN
              option_order := 0;
              FOR option_item IN SELECT * FROM jsonb_array_elements_text(question_item->'options') LOOP
                INSERT INTO public.quiz_options (
                  question_id,
                  option_text,
                  "order"
                ) VALUES (
                  new_question_id,
                  option_item,
                  option_order
                );
                option_order := option_order + 1;
              END LOOP;
            END IF;
          END;
          question_order := question_order + 1;
        END LOOP;
      END IF;
    END IF;
  END LOOP;
END $$;
*/

-- ============================================
-- XONG! Database đã được thiết kế lại
-- ============================================


-- 1. Insert new categories
INSERT INTO categories (id, name_ar, name_en, icon_name, color, "order") VALUES
('history', 'تاريخ', 'History', 'history_edu', '#D97706', 4),
('religion', 'دين', 'Religion', 'mosque', '#059669', 19)
ON CONFLICT (id) DO NOTHING;

-- 2. Migrate 'Religion' questions based on keywords
UPDATE questions
SET category_id = 'religion'
WHERE category_id = 'history_religion'
AND (
  question LIKE '%نبي%' OR
  question LIKE '%رسول%' OR
  question LIKE '%الله%' OR
  question LIKE '%قرآن%' OR
  question LIKE '%سورة%' OR
  question LIKE '%آية%' OR
  question LIKE '%إسلام%' OR
  question LIKE '%صلاة%' OR
  question LIKE '%زكاة%' OR
  question LIKE '%حج%' OR
  question LIKE '%صوم%' OR
  question LIKE '%كعبة%' OR
  question LIKE '%مكة%' OR
  question LIKE '%صحابي%' OR
  question LIKE '%إنجيل%' OR
  question LIKE '%توراة%' OR
  question LIKE '%مسيح%' OR
  question LIKE '%موسى%' OR
  question LIKE '%عيسى%' OR
  question LIKE '%محمد%' OR
  question LIKE '%إبراهيم%' OR
  question LIKE '%نوح%' OR
  question LIKE '%يوسف%' OR
  question LIKE '%يونس%' OR
  question LIKE '%آدم%' OR
  question LIKE '%حواء%' OR
  question LIKE '%جنة%' OR
  question LIKE '%نار%' OR
  question LIKE '%يوم القيامة%' OR
  question LIKE '%ملائكة%' OR
  question LIKE '%جن%' OR
  question LIKE '%شيطان%' OR
  question LIKE '%مسجد%' OR
  question LIKE '%كنيسة%' OR
  question LIKE '%غزوة%' OR
  question LIKE '%خديجة%' OR
  question LIKE '%عائشة%' OR
  question LIKE '%أبو بكر%' OR
  question LIKE '%عمر بن الخطاب%' OR
  question LIKE '%عثمان بن عفان%' OR
  question LIKE '%علي بن أبي طالب%' OR
  question LIKE '%خلق%' OR
  question LIKE '%سفر%' OR
  question LIKE '%خلفاء%' OR
  question LIKE '%راشدين%'
);

-- 3. Migrate remaining 'History & Religion' questions to 'History'
UPDATE questions
SET category_id = 'history'
WHERE category_id = 'history_religion';

-- 4. Delete the old category
DELETE FROM categories WHERE id = 'history_religion';

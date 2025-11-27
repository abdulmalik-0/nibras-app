-- 1. Get Question Counts per Category and Difficulty
CREATE OR REPLACE FUNCTION get_category_question_counts()
RETURNS TABLE (
  category_id text,
  difficulty text,
  count bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.category_id,
    q.difficulty,
    COUNT(*) as count
  FROM questions q
  GROUP BY q.category_id, q.difficulty
  ORDER BY q.category_id, q.difficulty;
END;
$$;

-- 2. Get General Report Stats
CREATE OR REPLACE FUNCTION get_report_stats()
RETURNS TABLE (
  total_reports bigint,
  pending_reports bigint,
  resolved_reports bigint,
  valid_reports bigint,
  invalid_reports bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) as total_reports,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_reports,
    COUNT(*) FILTER (WHERE status != 'pending') as resolved_reports,
    COUNT(*) FILTER (WHERE status = 'valid') as valid_reports,
    COUNT(*) FILTER (WHERE status = 'invalid') as invalid_reports
  FROM reports;
END;
$$;

-- 3. Get Top Admin Resolvers
CREATE OR REPLACE FUNCTION get_top_admin_resolvers()
RETURNS TABLE (
  admin_id uuid,
  email text,
  resolved_count bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.resolved_by as admin_id,
    u.email,
    COUNT(*) as resolved_count
  FROM reports r
  JOIN users u ON r.resolved_by = u.id
  WHERE r.resolved_by IS NOT NULL
  GROUP BY r.resolved_by, u.email
  ORDER BY resolved_count DESC
  LIMIT 10;
END;
$$;

-- 4. Get Most Played Categories (based on answered_questions)
CREATE OR REPLACE FUNCTION get_most_played_categories()
RETURNS TABLE (
  category_id text,
  play_count bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    q.category_id,
    COUNT(*) as play_count
  FROM answered_questions aq
  JOIN questions q ON aq.question_id = q.id
  GROUP BY q.category_id
  ORDER BY play_count DESC
  LIMIT 10;
END;
$$;

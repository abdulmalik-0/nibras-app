-- PostgreSQL Functions for Nibras App
-- Run these in Supabase SQL Editor AFTER running schema.sql

-- ============================================
-- FUNCTION: Increment questions answered count
-- ============================================
CREATE OR REPLACE FUNCTION increment_questions_answered(user_id_param UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET questions_answered_count = questions_answered_count + 1
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Increment report counts
-- ============================================
CREATE OR REPLACE FUNCTION increment_report_counts(
  question_id_param UUID,
  user_id_param UUID
)
RETURNS VOID AS $$
BEGIN
  -- Increment question's report_count
  UPDATE questions
  SET report_count = report_count + 1
  WHERE id = question_id_param;
  
  -- Increment user's reports_made_count
  UPDATE users
  SET reports_made_count = reports_made_count + 1
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Resolve report and update counters
-- ============================================
CREATE OR REPLACE FUNCTION resolve_report_counters(
  report_user_id UUID,
  admin_id_param UUID,
  is_valid_param BOOLEAN,
  question_id_param UUID
)
RETURNS VOID AS $$
BEGIN
  -- Update user's valid/invalid report count
  IF is_valid_param THEN
    UPDATE users
    SET valid_reports_count = valid_reports_count + 1
    WHERE id = report_user_id;
  ELSE
    UPDATE users
    SET invalid_reports_count = invalid_reports_count + 1
    WHERE id = report_user_id;
    
    -- Decrement question's report_count if invalid
    UPDATE questions
    SET report_count = GREATEST(report_count - 1, 0)
    WHERE id = question_id_param;
  END IF;
  
  -- Increment admin's resolved_reports_count
  UPDATE users
  SET resolved_reports_count = resolved_reports_count + 1
  WHERE id = admin_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Delete report and update counters
-- ============================================
CREATE OR REPLACE FUNCTION delete_report_counters(
  question_id_param UUID,
  user_id_param UUID
)
RETURNS VOID AS $$
BEGIN
  -- Decrement question's report_count
  UPDATE questions
  SET report_count = GREATEST(report_count - 1, 0)
  WHERE id = question_id_param;
  
  -- Decrement user's reports_made_count
  UPDATE users
  SET reports_made_count = GREATEST(reports_made_count - 1, 0)
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- FUNCTION: Delete user account
-- ============================================
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS VOID AS $$
BEGIN
  -- Delete from public.users first
  DELETE FROM public.users WHERE id = auth.uid();
  
  -- Delete from auth.users (requires SECURITY DEFINER)
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add color and order columns to categories table
-- Run this in Supabase SQL Editor

ALTER TABLE categories ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS "order" INTEGER;

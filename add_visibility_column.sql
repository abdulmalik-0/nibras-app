-- Add visibility column to categories table
ALTER TABLE categories 
ADD COLUMN visibility text DEFAULT 'public';

-- Update existing records based on is_vip_only
UPDATE categories 
SET visibility = 'vip_only' 
WHERE is_vip_only = true;

-- Optional: Drop is_vip_only column if you want to fully migrate
-- ALTER TABLE categories DROP COLUMN is_vip_only;

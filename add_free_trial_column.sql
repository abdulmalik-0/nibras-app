-- Add free_trial_usage column to users table
-- This stores a JSON object where keys are category IDs and values are ISO timestamps of the last trial usage
ALTER TABLE users 
ADD COLUMN free_trial_usage JSONB DEFAULT '{}'::jsonb;

-- Example usage:
-- UPDATE users SET free_trial_usage = '{"general_knowledge": "2023-11-26T10:00:00.000Z"}' WHERE id = '...';

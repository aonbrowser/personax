-- Add blocks column to store parsed markdown sections
ALTER TABLE analysis_results 
ADD COLUMN IF NOT EXISTS result_blocks JSONB;

-- Comment for documentation
COMMENT ON COLUMN analysis_results.result_blocks IS 'Parsed markdown content split into blocks by main headings for better readability';
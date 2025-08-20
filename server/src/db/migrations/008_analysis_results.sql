-- Create table for storing analysis results
CREATE TABLE IF NOT EXISTS analysis_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  analysis_type VARCHAR(50) NOT NULL, -- 'self', 'other', 'dyad', 'coach'
  status VARCHAR(20) NOT NULL DEFAULT 'processing', -- 'processing', 'completed', 'error'
  s0_data JSONB,
  s1_data JSONB,
  result_markdown TEXT,
  lifecoaching_notes JSONB,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB -- Additional data like language, confidence, etc.
);

-- Create indexes
CREATE INDEX idx_analysis_results_user_id ON analysis_results(user_id);
CREATE INDEX idx_analysis_results_status ON analysis_results(status);
CREATE INDEX idx_analysis_results_created_at ON analysis_results(created_at DESC);

-- Comments
COMMENT ON TABLE analysis_results IS 'Stores all analysis results with status tracking';
COMMENT ON COLUMN analysis_results.status IS 'Current status: processing, completed, or error';
COMMENT ON COLUMN analysis_results.s0_data IS 'S0 form data (stored for retry functionality)';
COMMENT ON COLUMN analysis_results.s1_data IS 'S1 form data (stored for retry functionality)';
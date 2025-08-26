-- Migration: Store form responses with analysis
-- This table stores all form responses linked to each analysis

CREATE TABLE IF NOT EXISTS form_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID NOT NULL REFERENCES analysis_results(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    item_id VARCHAR(100) NOT NULL,
    form VARCHAR(50) NOT NULL, -- Form1_Tanisalim, Form2_Kisilik, Form3_Davranis
    response_value TEXT, -- Stores the actual value (can be JSON for complex responses)
    response_label TEXT, -- Human-readable label
    response_type VARCHAR(50), -- Type of response (text, number, single_choice, multi_choice, etc.)
    
    -- Additional metadata for specific response types
    disc_most VARCHAR(10), -- For DISC questions
    disc_least VARCHAR(10), -- For DISC questions
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure unique response per analysis per item
    UNIQUE(analysis_id, item_id)
);

-- Create indexes for better query performance
CREATE INDEX idx_form_responses_analysis_id ON form_responses(analysis_id);
CREATE INDEX idx_form_responses_user_id ON form_responses(user_id);
CREATE INDEX idx_form_responses_form ON form_responses(form);
CREATE INDEX idx_form_responses_item_id ON form_responses(item_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_form_responses_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER form_responses_updated_at_trigger
BEFORE UPDATE ON form_responses
FOR EACH ROW
EXECUTE FUNCTION update_form_responses_updated_at();

-- Add column to analysis_results to track if responses are saved
ALTER TABLE analysis_results 
ADD COLUMN IF NOT EXISTS has_saved_responses BOOLEAN DEFAULT FALSE;

-- Create a view for easy retrieval of all responses for an analysis
CREATE OR REPLACE VIEW analysis_form_responses AS
SELECT 
    fr.*,
    ar.created_at as analysis_date,
    ar.analysis_type,
    u.email as user_email
FROM form_responses fr
JOIN analysis_results ar ON fr.analysis_id = ar.id
JOIN users u ON fr.user_id = u.id
ORDER BY fr.form, fr.item_id;

COMMENT ON TABLE form_responses IS 'Stores all form responses linked to each personality analysis';
COMMENT ON COLUMN form_responses.response_value IS 'Actual value - can be JSON for arrays/objects';
COMMENT ON COLUMN form_responses.response_label IS 'Human-readable version of the response';
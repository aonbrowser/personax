-- Migration for multiple subscription support
-- Allow users to have multiple active subscriptions

-- Modify user_subscriptions to support multiple active subscriptions
-- Remove unique constraint on user_id for active subscriptions if exists
ALTER TABLE user_subscriptions 
DROP CONSTRAINT IF EXISTS unique_active_subscription_per_user;

-- Add fields for better tracking
ALTER TABLE user_subscriptions 
ADD COLUMN IF NOT EXISTS credits_used JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS credits_remaining JSONB DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_primary BOOLEAN DEFAULT false;

-- Create function to get user's active subscriptions ordered by end_date
CREATE OR REPLACE FUNCTION get_user_active_subscriptions(p_user_id TEXT)
RETURNS TABLE (
    subscription_id TEXT,
    plan_id TEXT,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    status TEXT,
    credits_remaining JSONB,
    is_primary BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        us.id as subscription_id,
        us.plan_id,
        us.start_date,
        us.end_date,
        us.status,
        us.credits_remaining,
        us.is_primary
    FROM user_subscriptions us
    WHERE us.user_id = p_user_id 
        AND us.status = 'active'
        AND (us.end_date IS NULL OR us.end_date > NOW())
    ORDER BY 
        us.end_date ASC NULLS LAST,  -- Yakın zamanda bitecek olan önce
        us.created_at ASC;
END;
$$ LANGUAGE plpgsql;

-- Function to update subscription credits
CREATE OR REPLACE FUNCTION update_subscription_credits(
    p_subscription_id TEXT,
    p_service_type TEXT,
    p_amount INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_credits JSONB;
    v_new_value INTEGER;
BEGIN
    -- Get current credits
    SELECT credits_remaining INTO v_current_credits
    FROM user_subscriptions
    WHERE id = p_subscription_id;
    
    -- Calculate new value
    v_new_value := COALESCE((v_current_credits->p_service_type)::INTEGER, 0) - p_amount;
    
    -- Don't allow negative credits
    IF v_new_value < 0 THEN
        RETURN FALSE;
    END IF;
    
    -- Update credits
    UPDATE user_subscriptions
    SET credits_remaining = jsonb_set(
        COALESCE(credits_remaining, '{}'::jsonb),
        ARRAY[p_service_type],
        to_jsonb(v_new_value)
    ),
    credits_used = jsonb_set(
        COALESCE(credits_used, '{}'::jsonb),
        ARRAY[p_service_type],
        to_jsonb(COALESCE((credits_used->p_service_type)::INTEGER, 0) + p_amount)
    ),
    updated_at = CURRENT_TIMESTAMP
    WHERE id = p_subscription_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Initialize credits_remaining for existing subscriptions
UPDATE user_subscriptions us
SET credits_remaining = jsonb_build_object(
    'self_reanalysis', sp.self_reanalysis_limit,
    'other_analysis', sp.other_analysis_limit,
    'relationship_analysis', sp.relationship_analysis_limit,
    'coaching_tokens', sp.coaching_tokens_limit
)
FROM subscription_plans sp
WHERE us.plan_id = sp.id 
    AND us.credits_remaining = '{}'
    AND us.status = 'active';

-- Create purchase history table for PAYG
CREATE TABLE IF NOT EXISTS payg_purchases (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id TEXT NOT NULL,
    service_type TEXT NOT NULL,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    payment_status TEXT DEFAULT 'pending',
    payment_method TEXT,
    transaction_id TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_payg_purchases_user_id ON payg_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_end_date ON user_subscriptions(end_date);
-- Create coupons table
CREATE TABLE IF NOT EXISTS coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('free_subscription', 'discount', 'credit')),
    
    -- For free_subscription type
    plan_id VARCHAR(50) REFERENCES subscription_plans(id),
    duration_months INTEGER DEFAULT 1,
    
    -- For discount type
    discount_percent INTEGER CHECK (discount_percent >= 0 AND discount_percent <= 100),
    
    -- For credit type
    credit_amount INTEGER,
    credit_type VARCHAR(50),
    
    -- Usage limits
    max_uses INTEGER,
    uses_count INTEGER DEFAULT 0,
    one_time_per_user BOOLEAN DEFAULT true,
    
    -- Validity period
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    valid_until TIMESTAMP WITH TIME ZONE,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create coupon usage tracking table
CREATE TABLE IF NOT EXISTS coupon_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coupon_id UUID REFERENCES coupons(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subscription_id UUID REFERENCES user_subscriptions(id),
    
    UNIQUE(coupon_id, user_id) -- Ensure one-time use per user for applicable coupons
);

-- Add coupon_id to user_subscriptions table if not exists
ALTER TABLE user_subscriptions 
ADD COLUMN IF NOT EXISTS coupon_id UUID REFERENCES coupons(id);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_coupons_code ON coupons(code);
CREATE INDEX IF NOT EXISTS idx_coupons_valid_dates ON coupons(valid_from, valid_until);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_user ON coupon_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_coupon_usage_coupon ON coupon_usage(coupon_id);

-- Insert the CCBedava coupon (valid for 1 month from today)
INSERT INTO coupons (
    code,
    description,
    type,
    plan_id,
    duration_months,
    max_uses,
    one_time_per_user,
    valid_from,
    valid_until,
    is_active
) VALUES (
    'CCBEDAVA',
    '1 Aylık Standart Paket - Cogni Coach Deneme Kampanyası',
    'free_subscription',
    'standard',
    1,
    NULL, -- No limit on total uses
    true, -- Each user can use only once
    NOW(),
    NOW() + INTERVAL '1 month',
    true
) ON CONFLICT (code) DO UPDATE SET
    description = EXCLUDED.description,
    valid_until = EXCLUDED.valid_until,
    is_active = EXCLUDED.is_active;

-- Function to check if a coupon is valid
CREATE OR REPLACE FUNCTION is_coupon_valid(
    p_code VARCHAR,
    p_user_id UUID
) RETURNS TABLE (
    valid BOOLEAN,
    message TEXT,
    coupon_data JSONB
) AS $$
DECLARE
    v_coupon RECORD;
    v_usage_count INTEGER;
BEGIN
    -- Get coupon details
    SELECT * INTO v_coupon
    FROM coupons
    WHERE UPPER(code) = UPPER(p_code)
      AND is_active = true;
    
    -- Check if coupon exists
    IF v_coupon IS NULL THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon kodu bulunamadı'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check validity dates
    IF v_coupon.valid_from > NOW() THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon henüz aktif değil'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    IF v_coupon.valid_until IS NOT NULL AND v_coupon.valid_until < NOW() THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon süresi dolmuş'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check max uses
    IF v_coupon.max_uses IS NOT NULL AND v_coupon.uses_count >= v_coupon.max_uses THEN
        RETURN QUERY SELECT 
            false, 
            'Kupon kullanım limiti dolmuş'::TEXT,
            NULL::JSONB;
        RETURN;
    END IF;
    
    -- Check if user has already used this coupon (for one-time use coupons)
    IF v_coupon.one_time_per_user THEN
        SELECT COUNT(*) INTO v_usage_count
        FROM coupon_usage
        WHERE coupon_id = v_coupon.id AND user_id = p_user_id;
        
        IF v_usage_count > 0 THEN
            RETURN QUERY SELECT 
                false, 
                'Bu kuponu daha önce kullandınız'::TEXT,
                NULL::JSONB;
            RETURN;
        END IF;
    END IF;
    
    -- Coupon is valid
    RETURN QUERY SELECT 
        true,
        'Kupon geçerli'::TEXT,
        to_jsonb(v_coupon);
END;
$$ LANGUAGE plpgsql;
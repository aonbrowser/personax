-- Migration for In-App Purchase support
-- This adds tables to track IAP transactions and validation

-- Table to store IAP purchase records
CREATE TABLE IF NOT EXISTS iap_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android')),
  product_id VARCHAR(255) NOT NULL,
  transaction_id VARCHAR(255) UNIQUE NOT NULL,
  receipt_data TEXT,
  validation_status VARCHAR(50) DEFAULT 'pending',
  validation_response JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  validated_at TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_iap_user ON iap_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_iap_transaction ON iap_purchases(transaction_id);

-- Add IAP transaction ID to existing tables for tracking
ALTER TABLE user_subscriptions 
  ADD COLUMN IF NOT EXISTS iap_transaction_id VARCHAR(255),
  ADD CONSTRAINT fk_iap_transaction 
    FOREIGN KEY (iap_transaction_id) 
    REFERENCES iap_purchases(transaction_id);

ALTER TABLE payg_purchases 
  ADD COLUMN IF NOT EXISTS iap_transaction_id VARCHAR(255),
  ADD CONSTRAINT fk_payg_iap_transaction 
    FOREIGN KEY (iap_transaction_id) 
    REFERENCES iap_purchases(transaction_id);

-- Table for IAP product configuration
CREATE TABLE IF NOT EXISTS iap_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  platform VARCHAR(20) NOT NULL,
  product_id VARCHAR(255) NOT NULL,
  product_type VARCHAR(50) NOT NULL CHECK (product_type IN ('subscription', 'consumable', 'non_consumable')),
  plan_id VARCHAR(50),
  service_type VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(platform, product_id)
);

-- Insert default IAP products
INSERT INTO iap_products (platform, product_id, product_type, plan_id) VALUES
  -- iOS Subscriptions (auto-renewable)
  ('ios', 'com.personax.standard.monthly', 'subscription', 'standard'),
  ('ios', 'com.personax.extra.monthly', 'subscription', 'extra'),
  
  -- Android Subscriptions
  ('android', 'standard_monthly', 'subscription', 'standard'),
  ('android', 'extra_monthly', 'subscription', 'extra')
ON CONFLICT (platform, product_id) DO NOTHING;

-- PAYG products (consumables)
INSERT INTO iap_products (platform, product_id, product_type, service_type) VALUES
  -- iOS PAYG
  ('ios', 'com.personax.self.analysis', 'consumable', 'self_analysis'),
  ('ios', 'com.personax.other.analysis', 'consumable', 'other_analysis'),
  ('ios', 'com.personax.relationship.analysis', 'consumable', 'relationship_analysis'),
  
  -- Android PAYG
  ('android', 'self_analysis', 'consumable', 'self_analysis'),
  ('android', 'other_analysis', 'consumable', 'other_analysis'),
  ('android', 'relationship_analysis', 'consumable', 'relationship_analysis')
ON CONFLICT (platform, product_id) DO NOTHING;

-- Function to handle subscription renewal from IAP
CREATE OR REPLACE FUNCTION process_iap_renewal(
  p_user_id UUID,
  p_transaction_id VARCHAR(255),
  p_product_id VARCHAR(255),
  p_platform VARCHAR(20)
)
RETURNS BOOLEAN AS $$
DECLARE
  v_plan_id VARCHAR(50);
  v_plan RECORD;
BEGIN
  -- Get plan ID from product configuration
  SELECT plan_id INTO v_plan_id
  FROM iap_products
  WHERE platform = p_platform AND product_id = p_product_id;
  
  IF v_plan_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Get plan details
  SELECT * INTO v_plan
  FROM subscription_plans
  WHERE id = v_plan_id;
  
  IF v_plan IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Extend or create subscription
  INSERT INTO user_subscriptions (
    user_id,
    plan_id,
    start_date,
    end_date,
    status,
    credits_remaining,
    iap_transaction_id
  ) VALUES (
    p_user_id,
    v_plan_id,
    NOW(),
    NOW() + INTERVAL '1 month',
    'active',
    jsonb_build_object(
      'self_reanalysis', v_plan.self_reanalysis_limit,
      'other_analysis', v_plan.other_analysis_limit,
      'relationship_analysis', v_plan.relationship_analysis_limit,
      'coaching_tokens', v_plan.coaching_tokens_limit
    ),
    p_transaction_id
  )
  ON CONFLICT (user_id, plan_id) 
  DO UPDATE SET
    end_date = EXCLUDED.end_date,
    status = 'active',
    credits_remaining = EXCLUDED.credits_remaining,
    iap_transaction_id = EXCLUDED.iap_transaction_id;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
-- Pricing and Usage Tracking Tables
-- Created: 2025-08-19

-- Subscription Plans Table
CREATE TABLE IF NOT EXISTS subscription_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  self_analysis_limit INTEGER NOT NULL,
  self_reanalysis_limit INTEGER NOT NULL,
  other_analysis_limit INTEGER NOT NULL,
  relationship_analysis_limit INTEGER NOT NULL,
  coaching_tokens_limit INTEGER NOT NULL,
  price_usd DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pay As You Go Pricing Table
CREATE TABLE IF NOT EXISTS payg_pricing (
  id TEXT PRIMARY KEY,
  service_type TEXT NOT NULL, -- 'self_analysis', 'self_reanalysis', 'new_person', 'same_person_reanalysis', 'relationship', 'relationship_reanalysis', 'coaching_100k', 'coaching_500k'
  price_usd DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Subscriptions Table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan_id TEXT REFERENCES subscription_plans(id),
  status TEXT DEFAULT 'active', -- 'active', 'cancelled', 'expired', 'paused'
  billing_cycle TEXT DEFAULT 'monthly', -- 'monthly', 'yearly'
  start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  end_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Usage Tracking Table
CREATE TABLE IF NOT EXISTS usage_tracking (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  service_type TEXT NOT NULL, -- 'self_analysis', 'other_analysis', 'relationship_analysis', 'coaching'
  target_id TEXT, -- ID of analyzed person or relationship
  is_reanalysis BOOLEAN DEFAULT false,
  tokens_used INTEGER DEFAULT 0,
  input_tokens INTEGER DEFAULT 0,
  output_tokens INTEGER DEFAULT 0,
  cost_usd DECIMAL(10,4), -- Internal cost tracking (hidden from users)
  price_charged_usd DECIMAL(10,2), -- Price charged to user
  subscription_id UUID REFERENCES user_subscriptions(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Monthly Usage Summary Table (for quick quota checks)
CREATE TABLE IF NOT EXISTS monthly_usage_summary (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES user_subscriptions(id),
  month_year TEXT NOT NULL, -- Format: 'YYYY-MM'
  self_analysis_count INTEGER DEFAULT 0,
  self_reanalysis_count INTEGER DEFAULT 0,
  other_analysis_count INTEGER DEFAULT 0,
  relationship_analysis_count INTEGER DEFAULT 0,
  coaching_tokens_used INTEGER DEFAULT 0,
  total_cost_usd DECIMAL(10,4) DEFAULT 0, -- Internal tracking
  total_charged_usd DECIMAL(10,2) DEFAULT 0, -- User charges
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, month_year)
);

-- Token Costs Table (for internal cost calculation)
CREATE TABLE IF NOT EXISTS token_costs (
  id TEXT PRIMARY KEY,
  model_name TEXT NOT NULL, -- 'gpt-4', 'gpt-4-turbo', 'gpt-3.5-turbo', etc.
  input_cost_per_1k DECIMAL(10,6) NOT NULL,
  output_cost_per_1k DECIMAL(10,6) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default subscription plans
INSERT INTO subscription_plans (id, name, self_analysis_limit, self_reanalysis_limit, other_analysis_limit, relationship_analysis_limit, coaching_tokens_limit, price_usd) VALUES
('standard', 'Standart', 1, 2, 8, 8, 200000, 20.00),
('extra', 'Extra', 1, 5, 25, 25, 500000, 50.00)
ON CONFLICT (id) DO UPDATE SET
  self_reanalysis_limit = EXCLUDED.self_reanalysis_limit,
  other_analysis_limit = EXCLUDED.other_analysis_limit,
  relationship_analysis_limit = EXCLUDED.relationship_analysis_limit,
  coaching_tokens_limit = EXCLUDED.coaching_tokens_limit,
  price_usd = EXCLUDED.price_usd,
  updated_at = CURRENT_TIMESTAMP;

-- Insert Pay As You Go pricing
INSERT INTO payg_pricing (id, service_type, price_usd) VALUES
('payg_self', 'self_analysis', 5.00),
('payg_self_re', 'self_reanalysis', 3.00),
('payg_new_person', 'new_person', 3.00),
('payg_person_re', 'same_person_reanalysis', 2.00),
('payg_relationship', 'relationship', 3.00),
('payg_relationship_re', 'relationship_reanalysis', 2.00),
('payg_coaching_100k', 'coaching_100k', 5.00),
('payg_coaching_500k', 'coaching_500k', 20.00)
ON CONFLICT (id) DO UPDATE SET
  price_usd = EXCLUDED.price_usd,
  updated_at = CURRENT_TIMESTAMP;

-- Insert default token costs (OpenAI GPT-4 pricing as of 2024)
INSERT INTO token_costs (id, model_name, input_cost_per_1k, output_cost_per_1k) VALUES
('gpt-4', 'gpt-4', 0.03, 0.06),
('gpt-4-turbo', 'gpt-4-turbo-preview', 0.01, 0.03),
('gpt-3.5-turbo', 'gpt-3.5-turbo', 0.0005, 0.0015),
('gpt-4o', 'gpt-4o', 0.005, 0.015),
('gpt-4o-mini', 'gpt-4o-mini', 0.00015, 0.0006)
ON CONFLICT (id) DO UPDATE SET
  input_cost_per_1k = EXCLUDED.input_cost_per_1k,
  output_cost_per_1k = EXCLUDED.output_cost_per_1k,
  updated_at = CURRENT_TIMESTAMP;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_usage_tracking_user_id ON usage_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_usage_tracking_created_at ON usage_tracking(created_at);
CREATE INDEX IF NOT EXISTS idx_monthly_usage_user_month ON monthly_usage_summary(user_id, month_year);

-- Function to update monthly usage summary
CREATE OR REPLACE FUNCTION update_monthly_usage()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO monthly_usage_summary (
    user_id, 
    subscription_id,
    month_year,
    self_analysis_count,
    self_reanalysis_count,
    other_analysis_count,
    relationship_analysis_count,
    coaching_tokens_used,
    total_cost_usd,
    total_charged_usd
  ) VALUES (
    NEW.user_id,
    NEW.subscription_id,
    TO_CHAR(NEW.created_at, 'YYYY-MM'),
    CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    COALESCE(NEW.cost_usd, 0),
    COALESCE(NEW.price_charged_usd, 0)
  )
  ON CONFLICT (user_id, month_year) DO UPDATE SET
    self_analysis_count = monthly_usage_summary.self_analysis_count + 
      CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    self_reanalysis_count = monthly_usage_summary.self_reanalysis_count + 
      CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    other_analysis_count = monthly_usage_summary.other_analysis_count + 
      CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    relationship_analysis_count = monthly_usage_summary.relationship_analysis_count + 
      CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    coaching_tokens_used = monthly_usage_summary.coaching_tokens_used + 
      CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    total_cost_usd = monthly_usage_summary.total_cost_usd + COALESCE(NEW.cost_usd, 0),
    total_charged_usd = monthly_usage_summary.total_charged_usd + COALESCE(NEW.price_charged_usd, 0),
    updated_at = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic monthly usage updates
DROP TRIGGER IF EXISTS trigger_update_monthly_usage ON usage_tracking;
CREATE TRIGGER trigger_update_monthly_usage
  AFTER INSERT ON usage_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_monthly_usage();
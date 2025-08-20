-- Create or replace function to update monthly usage summary
CREATE OR REPLACE FUNCTION update_monthly_usage_summary()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert or update monthly summary
  INSERT INTO monthly_usage_summary (
    user_id,
    month_year,
    subscription_id,
    self_analysis_count,
    self_reanalysis_count,
    other_analysis_count,
    relationship_analysis_count,
    coaching_tokens_used,
    total_cost_usd,
    total_charged_usd
  )
  VALUES (
    NEW.user_id,
    TO_CHAR(NEW.created_at, 'YYYY-MM'),
    NEW.subscription_id,
    CASE WHEN NEW.service_type = 'self_analysis' AND NOT NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'self_analysis' AND NEW.is_reanalysis THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'other_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'relationship_analysis' THEN 1 ELSE 0 END,
    CASE WHEN NEW.service_type = 'coaching' THEN NEW.tokens_used ELSE 0 END,
    NEW.cost_usd,
    NEW.price_charged_usd
  )
  ON CONFLICT (user_id, month_year) DO UPDATE SET
    subscription_id = COALESCE(monthly_usage_summary.subscription_id, NEW.subscription_id),
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
    total_cost_usd = monthly_usage_summary.total_cost_usd + NEW.cost_usd,
    total_charged_usd = monthly_usage_summary.total_charged_usd + NEW.price_charged_usd,
    updated_at = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for usage_tracking table
DROP TRIGGER IF EXISTS update_monthly_usage_on_insert ON usage_tracking;
CREATE TRIGGER update_monthly_usage_on_insert
AFTER INSERT ON usage_tracking
FOR EACH ROW
EXECUTE FUNCTION update_monthly_usage_summary();
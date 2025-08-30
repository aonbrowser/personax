import { pool } from '../db/pool';

export class CreditManager {
  static async deductCredit(userId: string, serviceType: string = 'analysis'): Promise<{ success: boolean; error?: string }> {
    try {
      // Start transaction
      await pool.query('BEGIN');
      
      // Get user's active subscriptions ordered by expiry date (soonest first)
      const subsResult = await pool.query(`
        SELECT 
          us.id,
          us.plan_id,
          sp.total_analysis_credits,
          us.credits_used,
          us.end_date
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = $1 
          AND (us.status = 'active' OR us.status = 'cancelled')
          AND (us.end_date IS NULL OR us.end_date > NOW())
          AND (sp.total_analysis_credits IS NULL OR us.credits_used < sp.total_analysis_credits)
        ORDER BY us.end_date ASC NULLS LAST
        LIMIT 1
        FOR UPDATE
      `, [userId]);
      
      if (subsResult.rows.length === 0) {
        await pool.query('ROLLBACK');
        return { success: false, error: 'No active subscription with available credits' };
      }
      
      const subscription = subsResult.rows[0];
      
      // Increment credits_used
      await pool.query(`
        UPDATE user_subscriptions 
        SET credits_used = credits_used + 1,
            updated_at = NOW()
        WHERE id = $1
      `, [subscription.id]);
      
      // Log usage
      await pool.query(`
        INSERT INTO usage_tracking (
          user_id, 
          subscription_id, 
          service_type, 
          credits_consumed,
          created_at
        ) VALUES ($1, $2, $3, 1, NOW())
      `, [userId, subscription.id, serviceType]);
      
      // Update monthly summary
      const currentMonth = new Date().toISOString().slice(0, 7);
      await pool.query(`
        INSERT INTO monthly_usage_summary (
          user_id,
          subscription_id,
          month_year,
          self_analysis_count,
          created_at,
          updated_at
        ) VALUES ($1, $2, $3, 1, NOW(), NOW())
        ON CONFLICT (user_id, subscription_id, month_year) 
        DO UPDATE SET 
          self_analysis_count = monthly_usage_summary.self_analysis_count + 1,
          updated_at = NOW()
      `, [userId, subscription.id, currentMonth]);
      
      await pool.query('COMMIT');
      return { success: true };
      
    } catch (error) {
      await pool.query('ROLLBACK');
      console.error('Error deducting credit:', error);
      return { success: false, error: 'Failed to deduct credit' };
    }
  }
  
  static async checkCredits(userId: string): Promise<{ hasCredits: boolean; availableCredits: number }> {
    try {
      const result = await pool.query(`
        SELECT 
          SUM(sp.total_analysis_credits - us.credits_used) as available_credits
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = $1 
          AND (us.status = 'active' OR us.status = 'cancelled')
          AND (us.end_date IS NULL OR us.end_date > NOW())
          AND (sp.total_analysis_credits IS NULL OR us.credits_used < sp.total_analysis_credits)
      `, [userId]);
      
      const availableCredits = parseInt(result.rows[0]?.available_credits || '0');
      return {
        hasCredits: availableCredits > 0,
        availableCredits
      };
    } catch (error) {
      console.error('Error checking credits:', error);
      return { hasCredits: false, availableCredits: 0 };
    }
  }
}
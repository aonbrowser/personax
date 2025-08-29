import { pool } from '../db/pool';

interface TokenUsage {
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  modelName: string;
}

interface UsageTrackingData {
  userId: string;
  serviceType: 'self_analysis' | 'other_analysis' | 'relationship_analysis' | 'coaching';
  targetId?: string;
  isReanalysis: boolean;
  tokenUsage?: TokenUsage;
  subscriptionId?: string;
}

export class UsageTracker {
  /**
   * Calculate the internal cost of token usage
   */
  static async calculateCost(tokenUsage: TokenUsage): Promise<number> {
    try {
      // Get token costs for the model
      const result = await pool.query(`
        SELECT input_cost_per_1k, output_cost_per_1k 
        FROM token_costs 
        WHERE model_name = $1 AND is_active = true
        LIMIT 1
      `, [tokenUsage.modelName]);

      if (result.rows.length === 0) {
        // Default to GPT-4 pricing if model not found
        console.warn(`Token costs not found for model: ${tokenUsage.modelName}, using GPT-4 defaults`);
        const inputCost = (tokenUsage.inputTokens / 1000) * 0.03;
        const outputCost = (tokenUsage.outputTokens / 1000) * 0.06;
        return inputCost + outputCost;
      }

      const costs = result.rows[0];
      const inputCost = (tokenUsage.inputTokens / 1000) * costs.input_cost_per_1k;
      const outputCost = (tokenUsage.outputTokens / 1000) * costs.output_cost_per_1k;
      
      return inputCost + outputCost;
    } catch (error) {
      console.error('Error calculating token cost:', error);
      return 0;
    }
  }

  /**
   * Check if user has exceeded their limits (with multi-subscription support)
   */
  static async checkLimits(userId: string, serviceType: string): Promise<{
    allowed: boolean;
    reason?: string;
    subscription?: any;
    monthlyUsage?: any;
  }> {
    try {
      // Get all user's active subscriptions ordered by end_date (soonest first)
      const subResult = await pool.query(`
        SELECT 
          us.*,
          sp.*,
          us.credits_remaining
        FROM user_subscriptions us
        JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE us.user_id = $1 
          AND us.status = 'active'
          AND (us.end_date IS NULL OR us.end_date > NOW())
        ORDER BY us.end_date ASC NULLS LAST, us.created_at ASC
      `, [userId]);

      const currentMonth = new Date().toISOString().slice(0, 7);

      // Get monthly usage
      const usageResult = await pool.query(`
        SELECT * FROM monthly_usage_summary
        WHERE user_id = $1 AND month_year = $2
      `, [userId, currentMonth]);

      const subscriptions = subResult.rows;
      const monthlyUsage = usageResult.rows[0] || {
        self_analysis_count: 0,
        self_reanalysis_count: 0,
        other_analysis_count: 0,
        relationship_analysis_count: 0,
        coaching_tokens_used: 0,
      };

      // If no subscription, check PAYG limits (for now, allow all PAYG)
      if (!subscriptions || subscriptions.length === 0) {
        return {
          allowed: true,
          subscription: null,
          monthlyUsage
        };
      }

      // Check each subscription for available credits
      let availableSubscription = null;
      let creditKey = '';
      
      // Map service type to credit key
      switch (serviceType) {
        case 'self_analysis':
          creditKey = 'self_reanalysis';
          // First self analysis is always included
          if (monthlyUsage.self_analysis_count === 0) {
            return { allowed: true, subscription: subscriptions[0], monthlyUsage };
          }
          break;
        case 'other_analysis':
          creditKey = 'other_analysis';
          break;
        case 'relationship_analysis':
          creditKey = 'relationship_analysis';
          break;
        case 'coaching':
          creditKey = 'coaching_tokens';
          break;
      }

      // Find first subscription with available credits (already sorted by end_date)
      for (const sub of subscriptions) {
        const credits = sub.credits_remaining || {};
        
        // Check if this subscription has credits for this service
        if (credits[creditKey] && credits[creditKey] > 0) {
          availableSubscription = sub;
          break;
        }
      }

      if (availableSubscription) {
        return { allowed: true, subscription: availableSubscription, monthlyUsage };
      }

      // No subscription has available credits
      const totalLimit = subscriptions.reduce((sum, sub) => {
        return sum + (sub[creditKey + '_limit'] || 0);
      }, 0);

      return {
        allowed: false,
        reason: `Tüm aboneliklerinizdeki ${serviceType} limitleri doldu. Yeni abonelik alabilir veya tek seferlik ödeme yapabilirsiniz.`,
        subscription: subscriptions[0], // Return first subscription for reference
        monthlyUsage
      };
    } catch (error) {
      console.error('Error checking usage limits:', error);
      // Allow on error to not block users
      return { allowed: true };
    }
  }

  /**
   * Get the price to charge for a service
   */
  static async getServicePrice(
    serviceType: string,
    isReanalysis: boolean,
    subscription: any
  ): Promise<number> {
    // If user has subscription and within limits, no charge
    if (subscription) {
      return 0;
    }

    // Get PAYG pricing
    let pricingType = serviceType;
    
    if (serviceType === 'self_analysis') {
      pricingType = isReanalysis ? 'self_reanalysis' : 'self_analysis';
    } else if (serviceType === 'other_analysis') {
      pricingType = isReanalysis ? 'same_person_reanalysis' : 'new_person';
    } else if (serviceType === 'relationship_analysis') {
      pricingType = isReanalysis ? 'relationship_reanalysis' : 'relationship';
    }

    try {
      const result = await pool.query(`
        SELECT price_usd FROM payg_pricing
        WHERE service_type = $1 AND is_active = true
        LIMIT 1
      `, [pricingType]);

      return result.rows[0]?.price_usd || 0;
    } catch (error) {
      console.error('Error getting service price:', error);
      return 0;
    }
  }

  /**
   * Check if this is a reanalysis
   */
  static async isReanalysis(
    userId: string, 
    serviceType: string, 
    targetId?: string
  ): Promise<boolean> {
    if (!targetId || serviceType === 'coaching') {
      return false;
    }

    try {
      const result = await pool.query(`
        SELECT COUNT(*) as count
        FROM usage_tracking
        WHERE user_id = $1 
          AND service_type = $2 
          AND target_id = $3
          AND created_at > NOW() - INTERVAL '30 days'
      `, [userId, serviceType, targetId]);

      return parseInt(result.rows[0].count) > 0;
    } catch (error) {
      console.error('Error checking reanalysis:', error);
      return false;
    }
  }

  /**
   * Track usage of a service
   */
  static async trackUsage(data: UsageTrackingData): Promise<void> {
    try {
      const {
        userId,
        serviceType,
        targetId,
        isReanalysis,
        tokenUsage,
        subscriptionId
      } = data;

      // Calculate costs
      let costUsd = 0;
      let inputTokens = 0;
      let outputTokens = 0;
      let totalTokens = 0;

      if (tokenUsage) {
        costUsd = await this.calculateCost(tokenUsage);
        inputTokens = tokenUsage.inputTokens;
        outputTokens = tokenUsage.outputTokens;
        totalTokens = tokenUsage.totalTokens;
      }

      // Get subscription info if not provided
      // Check if subscriptionId is a valid UUID, otherwise set to null
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      let subId = (subscriptionId && uuidRegex.test(subscriptionId)) ? subscriptionId : null;
      if (!subId) {
        const subResult = await pool.query(`
          SELECT id FROM user_subscriptions
          WHERE user_id = $1 AND status = 'active'
          ORDER BY created_at DESC
          LIMIT 1
        `, [userId]);
        subId = subResult.rows[0]?.id;
      }

      // Get price to charge
      const priceCharged = await this.getServicePrice(
        serviceType,
        isReanalysis,
        subId ? { id: subId } : null
      );

      // Insert usage record
      await pool.query(`
        INSERT INTO usage_tracking (
          user_id,
          service_type,
          target_id,
          is_reanalysis,
          tokens_used,
          input_tokens,
          output_tokens,
          cost_usd,
          price_charged_usd,
          subscription_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      `, [
        userId,
        serviceType,
        targetId,
        isReanalysis,
        totalTokens,
        inputTokens,
        outputTokens,
        costUsd,
        priceCharged,
        subId
      ]);

      console.log(`Usage tracked: ${serviceType} for user ${userId}, cost: $${costUsd.toFixed(4)}, charged: $${priceCharged}`);
    } catch (error) {
      console.error('Error tracking usage:', error);
      // Don't throw to not block the main flow
    }
  }

  /**
   * Get user's current month usage summary
   */
  static async getUserUsageSummary(userId: string): Promise<any> {
    try {
      const currentMonth = new Date().toISOString().slice(0, 7);
      
      const result = await pool.query(`
        SELECT 
          mus.*,
          sp.name as plan_name,
          sp.self_reanalysis_limit,
          sp.other_analysis_limit,
          sp.relationship_analysis_limit,
          sp.coaching_tokens_limit
        FROM monthly_usage_summary mus
        LEFT JOIN user_subscriptions us ON mus.subscription_id = us.id
        LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
        WHERE mus.user_id = $1 AND mus.month_year = $2
      `, [userId, currentMonth]);

      if (result.rows.length === 0) {
        // Return empty usage
        return {
          month_year: currentMonth,
          self_analysis_count: 0,
          self_reanalysis_count: 0,
          other_analysis_count: 0,
          relationship_analysis_count: 0,
          coaching_tokens_used: 0,
          total_charged_usd: 0,
          plan_name: null,
          limits: null
        };
      }

      return result.rows[0];
    } catch (error) {
      console.error('Error getting user usage summary:', error);
      return null;
    }
  }
}
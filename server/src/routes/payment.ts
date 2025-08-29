import { Router, Request, Response } from 'express';
import { pool } from '../db/pool';
import { UsageTracker } from '../services/usage-tracker';

const router = Router();

// Check user's limits for a service
router.get('/check-limits', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required', hasCredit: false });
  }
  const serviceType = req.query.service_type as string;
  
  if (!serviceType) {
    return res.status(400).json({ error: 'service_type is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Get all active subscriptions with plan details
    const subsResult = await pool.query(`
      SELECT 
        sub.*,
        sp.self_analysis_limit,
        sp.self_reanalysis_limit,
        sp.other_analysis_limit,
        sp.relationship_analysis_limit,
        sp.coaching_tokens_limit
      FROM get_user_active_subscriptions($1) sub
      LEFT JOIN subscription_plans sp ON sub.plan_id = sp.id
    `, [userId]);
    
    const subscriptions = subsResult.rows;
    
    // Check if user has any subscription with available credits
    let hasCredit = false;
    let availableSubscription = null;
    
    for (const sub of subscriptions) {
      const credits = sub.credits_remaining || {};
      let creditKey = '';
      
      // Map service type to credit key
      switch (serviceType) {
        case 'self_analysis':
          // Check if user has done self analysis before
          const analysisCount = await pool.query(`
            SELECT COUNT(*) as count FROM analysis_results
            WHERE user_id = $1 AND analysis_type = 'self'
          `, [userId]);
          
          // If no previous analysis, use self_analysis credit, otherwise self_reanalysis
          creditKey = analysisCount.rows[0].count === 0 ? 'self_analysis' : 'self_reanalysis';
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
      
      if (credits[creditKey] && credits[creditKey] > 0) {
        hasCredit = true;
        availableSubscription = sub;
        break;
      }
    }
    
    // Get current month usage for additional info
    const currentMonth = new Date().toISOString().slice(0, 7);
    const usageResult = await pool.query(`
      SELECT * FROM monthly_usage_summary
      WHERE user_id = $1 AND month_year = $2
    `, [userId, currentMonth]);
    
    const monthlyUsage = usageResult.rows[0] || {
      self_analysis_count: 0,
      self_reanalysis_count: 0,
      other_analysis_count: 0,
      relationship_analysis_count: 0,
      coaching_tokens_used: 0,
    };
    
    res.json({
      hasCredit,
      availableSubscription,
      subscriptions,
      monthlyUsage,
      serviceType
    });
  } catch (error) {
    console.error('Error checking limits:', error);
    res.status(500).json({ error: 'Failed to check limits' });
  }
});

// Cancel subscription endpoint
router.post('/subscriptions/:subscriptionId/cancel', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  const { subscriptionId } = req.params;
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  
  if (!subscriptionId) {
    return res.status(400).json({ error: 'subscription_id is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Verify the subscription belongs to the user
    const subResult = await pool.query(`
      SELECT * FROM user_subscriptions 
      WHERE id = $1 AND user_id = $2 AND status = 'active'
    `, [subscriptionId, userId]);
    
    if (subResult.rows.length === 0) {
      return res.status(404).json({ error: 'Active subscription not found' });
    }
    
    // Cancel the subscription (it will remain active until end_date)
    // Status becomes 'cancelled' but subscription remains usable until end_date
    await pool.query(`
      UPDATE user_subscriptions 
      SET status = 'cancelled',
          updated_at = NOW()
      WHERE id = $1
    `, [subscriptionId]);
    
    res.json({ 
      success: true, 
      message: 'Subscription cancelled successfully',
      subscription: {
        ...subResult.rows[0],
        status: 'cancelled'
      }
    });
  } catch (error) {
    console.error('Error cancelling subscription:', error);
    res.status(500).json({ error: 'Failed to cancel subscription' });
  }
});

// Get pricing options based on user's current situation
router.get('/pricing-options', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const serviceType = req.query.service_type as string;
  
  if (!serviceType) {
    return res.status(400).json({ error: 'service_type is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Get user's active subscriptions
    const subsResult = await pool.query(`
      SELECT * FROM get_user_active_subscriptions($1)
    `, [userId]);
    
    const activeSubscriptions = subsResult.rows;
    
    // Get all subscription plans
    const plansResult = await pool.query(`
      SELECT * FROM subscription_plans 
      WHERE is_active = true 
      ORDER BY price_usd ASC
    `);
    
    // Get PAYG pricing for the specific service
    let paygServiceType = serviceType;
    if (serviceType === 'self_analysis') {
      // Check if it's first analysis or reanalysis
      const usageResult = await pool.query(`
        SELECT COUNT(*) as count FROM usage_tracking
        WHERE user_id = $1 AND service_type = 'self_analysis'
        AND created_at > NOW() - INTERVAL '30 days'
      `, [userId]);
      
      paygServiceType = usageResult.rows[0].count > 0 ? 'self_reanalysis' : 'self_analysis';
    } else if (serviceType === 'other_analysis') {
      paygServiceType = 'new_person'; // Simplified, could check for same person
    } else if (serviceType === 'relationship_analysis') {
      paygServiceType = 'relationship';
    }
    
    const paygResult = await pool.query(`
      SELECT * FROM payg_pricing 
      WHERE service_type = $1 AND is_active = true
    `, [paygServiceType]);
    
    const options = {
      hasActiveSubscription: activeSubscriptions.length > 0,
      subscriptions: activeSubscriptions,
      availablePlans: plansResult.rows,
      paygOption: paygResult.rows[0],
      recommendations: []
    };
    
    // Add recommendations
    if (!options.hasActiveSubscription) {
      options.recommendations.push({
        type: 'new_subscription',
        message: 'Abonelik alarak daha uygun fiyatlarla analiz yapabilirsiniz'
      });
    } else {
      const hasLimitedCredits = activeSubscriptions.every(sub => {
        const credits = sub.credits_remaining || {};
        return Object.values(credits).every(c => (c as number) <= 0);
      });
      
      if (hasLimitedCredits) {
        options.recommendations.push({
          type: 'additional_subscription',
          message: 'Mevcut abonelik limitiniz dolmuş. Yeni bir abonelik alabilir veya tek seferlik ödeme yapabilirsiniz'
        });
      }
    }
    
    res.json(options);
  } catch (error) {
    console.error('Error getting pricing options:', error);
    res.status(500).json({ error: 'Failed to get pricing options' });
  }
});

// Purchase a new subscription
router.post('/purchase-subscription', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const { planId } = req.body;
  
  if (!planId) {
    return res.status(400).json({ error: 'planId is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Get plan details
    const planResult = await pool.query(`
      SELECT * FROM subscription_plans WHERE id = $1 AND is_active = true
    `, [planId]);
    
    if (planResult.rows.length === 0) {
      return res.status(404).json({ error: 'Plan not found' });
    }
    
    const plan = planResult.rows[0];
    
    // Create new subscription
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + 1); // 1 month subscription
    
    const subResult = await pool.query(`
      INSERT INTO user_subscriptions (
        user_id, 
        plan_id, 
        start_date, 
        end_date, 
        status,
        credits_remaining
      ) VALUES ($1, $2, NOW(), $3, 'active', $4)
      RETURNING *
    `, [
      userId, 
      planId, 
      endDate,
      JSON.stringify({
        self_reanalysis: plan.self_reanalysis_limit,
        other_analysis: plan.other_analysis_limit,
        relationship_analysis: plan.relationship_analysis_limit,
        coaching_tokens: plan.coaching_tokens_limit
      })
    ]);
    
    res.json({
      success: true,
      subscription: subResult.rows[0],
      message: 'Abonelik başarıyla satın alındı'
    });
  } catch (error) {
    console.error('Error purchasing subscription:', error);
    res.status(500).json({ error: 'Failed to purchase subscription' });
  }
});

// Purchase PAYG service
router.post('/purchase-payg', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const { serviceType, quantity = 1 } = req.body;
  
  if (!serviceType) {
    return res.status(400).json({ error: 'serviceType is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Get PAYG pricing
    const pricingResult = await pool.query(`
      SELECT * FROM payg_pricing 
      WHERE service_type = $1 AND is_active = true
    `, [serviceType]);
    
    if (pricingResult.rows.length === 0) {
      return res.status(404).json({ error: 'Pricing not found' });
    }
    
    const pricing = pricingResult.rows[0];
    const totalPrice = pricing.price_usd * quantity;
    
    // Record purchase
    const purchaseResult = await pool.query(`
      INSERT INTO payg_purchases (
        user_id,
        service_type,
        quantity,
        unit_price,
        total_price,
        payment_status
      ) VALUES ($1, $2, $3, $4, $5, 'completed')
      RETURNING *
    `, [userId, serviceType, quantity, pricing.price_usd, totalPrice]);
    
    res.json({
      success: true,
      purchase: purchaseResult.rows[0],
      message: 'Tek seferlik ödeme başarıyla alındı'
    });
  } catch (error) {
    console.error('Error purchasing PAYG:', error);
    res.status(500).json({ error: 'Failed to purchase PAYG service' });
  }
});

// Validate In-App Purchase
router.post('/validate-purchase', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const { platform, productId, transactionId, receipt, purchaseToken } = req.body;
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // TODO: Validate with Apple/Google servers
    // For now, we'll trust the client (NOT FOR PRODUCTION)
    let isValid = false;
    
    if (platform === 'ios') {
      // Validate with Apple
      // const validationResult = await validateWithApple(receipt);
      // isValid = validationResult.status === 0;
      isValid = true; // Mock for development
    } else if (platform === 'android') {
      // Validate with Google Play
      // const validationResult = await validateWithGoogle(productId, purchaseToken);
      // isValid = validationResult.purchaseState === 0;
      isValid = true; // Mock for development
    }
    
    if (isValid) {
      // Record the purchase
      await pool.query(`
        INSERT INTO iap_purchases (
          user_id,
          platform,
          product_id,
          transaction_id,
          receipt_data,
          validation_status,
          created_at
        ) VALUES ($1, $2, $3, $4, $5, 'valid', NOW())
      `, [userId, platform, productId, transactionId, receipt || purchaseToken]);
      
      // Grant the appropriate subscription or credits
      if (productId.includes('monthly')) {
        // It's a subscription
        const planId = productId.includes('standard') ? 'standard' : 'extra';
        
        // Get plan details
        const planResult = await pool.query(`
          SELECT * FROM subscription_plans WHERE id = $1
        `, [planId]);
        
        if (planResult.rows.length > 0) {
          const plan = planResult.rows[0];
          const endDate = new Date();
          endDate.setMonth(endDate.getMonth() + 1);
          
          // Create subscription
          await pool.query(`
            INSERT INTO user_subscriptions (
              user_id, 
              plan_id, 
              start_date, 
              end_date, 
              status,
              credits_remaining,
              iap_transaction_id
            ) VALUES ($1, $2, NOW(), $3, 'active', $4, $5)
          `, [
            userId, 
            planId, 
            endDate,
            JSON.stringify({
              self_reanalysis: plan.self_reanalysis_limit,
              other_analysis: plan.other_analysis_limit,
              relationship_analysis: plan.relationship_analysis_limit,
              coaching_tokens: plan.coaching_tokens_limit
            }),
            transactionId
          ]);
        }
      } else {
        // It's a one-time purchase
        // Grant immediate access to the service
        await pool.query(`
          INSERT INTO payg_purchases (
            user_id,
            service_type,
            quantity,
            unit_price,
            total_price,
            payment_status,
            iap_transaction_id
          ) VALUES ($1, $2, 1, 5.00, 5.00, 'completed', $3)
        `, [userId, productId.replace('com.personax.', '').replace('.', '_'), transactionId]);
      }
      
      res.json({ valid: true, message: 'Purchase validated successfully' });
    } else {
      res.json({ valid: false, message: 'Invalid purchase receipt' });
    }
  } catch (error) {
    console.error('Error validating purchase:', error);
    res.status(500).json({ error: 'Failed to validate purchase' });
  }
});

// Validate and apply coupon code
router.post('/validate-coupon', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required', valid: false });
  }
  const { couponCode, serviceType } = req.body;
  
  if (!couponCode) {
    return res.status(400).json({ error: 'couponCode is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Check if coupon exists and is valid
    const couponResult = await pool.query(`
      SELECT * FROM coupons 
      WHERE code = $1 
        AND is_active = true 
        AND (valid_from IS NULL OR valid_from <= NOW())
        AND (valid_until IS NULL OR valid_until >= NOW())
        AND (max_uses IS NULL OR uses_count < max_uses)
    `, [couponCode.toUpperCase()]);
    
    if (couponResult.rows.length === 0) {
      return res.status(400).json({ 
        valid: false,
        message: 'Geçersiz veya süresi dolmuş kupon kodu' 
      });
    }
    
    const coupon = couponResult.rows[0];
    
    // Check if user has already used this coupon (for one-time use coupons)
    if (coupon.one_time_per_user) {
      const usageResult = await pool.query(`
        SELECT * FROM coupon_usage 
        WHERE coupon_id = $1 AND user_id = $2
      `, [coupon.id, userId]);
      
      if (usageResult.rows.length > 0) {
        return res.status(400).json({ 
          valid: false,
          message: 'Bu kuponu daha önce kullandınız' 
        });
      }
    }
    
    // Apply coupon based on type
    if (coupon.type === 'free_subscription') {
      // Get the plan details
      const planResult = await pool.query(`
        SELECT * FROM subscription_plans WHERE id = $1
      `, [coupon.plan_id || 'standard']);
      
      if (planResult.rows.length === 0) {
        return res.status(500).json({ error: 'Subscription plan not found' });
      }
      
      const plan = planResult.rows[0];
      const durationMonths = coupon.duration_months || 1;
      const endDate = new Date();
      endDate.setMonth(endDate.getMonth() + durationMonths);
      
      // Create subscription for user
      const subResult = await pool.query(`
        INSERT INTO user_subscriptions (
          user_id, 
          plan_id, 
          start_date, 
          end_date, 
          status,
          credits_remaining,
          coupon_id
        ) VALUES ($1, $2, NOW(), $3, 'active', $4, $5)
        RETURNING *
      `, [
        userId, 
        coupon.plan_id || 'standard', 
        endDate,
        JSON.stringify({
          self_analysis: plan.self_analysis_limit || 1, // Add self_analysis credit
          self_reanalysis: plan.self_reanalysis_limit,
          other_analysis: plan.other_analysis_limit,
          relationship_analysis: plan.relationship_analysis_limit,
          coaching_tokens: plan.coaching_tokens_limit
        }),
        coupon.id
      ]);
      
      // Record coupon usage
      await pool.query(`
        INSERT INTO coupon_usage (coupon_id, user_id, used_at)
        VALUES ($1, $2, NOW())
      `, [coupon.id, userId]);
      
      // Increment coupon usage count
      await pool.query(`
        UPDATE coupons 
        SET uses_count = uses_count + 1 
        WHERE id = $1
      `, [coupon.id]);
      
      res.json({
        valid: true,
        message: `${durationMonths} aylık ${plan.name} paketi başarıyla eklendi!`,
        coupon: {
          type: coupon.type,
          description: coupon.description,
          plan_name: plan.name,
          duration_months: durationMonths
        }
      });
    } else if (coupon.type === 'discount') {
      // For discount coupons, just validate and return the discount info
      res.json({
        valid: true,
        message: `%${coupon.discount_percent} indirim uygulandı`,
        coupon: {
          type: coupon.type,
          discount_percent: coupon.discount_percent,
          description: coupon.description
        }
      });
    } else {
      res.status(400).json({ 
        valid: false,
        message: 'Bilinmeyen kupon tipi' 
      });
    }
  } catch (error) {
    console.error('Error validating coupon:', error);
    res.status(500).json({ error: 'Kupon doğrulanamadı' });
  }
});

// Use credits from subscription
router.post('/use-credits', async (req: Request, res: Response) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const { serviceType, subscriptionId } = req.body;
  
  if (!serviceType) {
    return res.status(400).json({ error: 'serviceType is required' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query(`
      SELECT id FROM users WHERE email = $1
    `, [userEmail]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    let creditKey = '';
    let amount = 1;
    
    // Map service type to credit key
    switch (serviceType) {
      case 'self_analysis':
        creditKey = 'self_reanalysis';
        break;
      case 'other_analysis':
        creditKey = 'other_analysis';
        break;
      case 'relationship_analysis':
        creditKey = 'relationship_analysis';
        break;
      case 'coaching':
        creditKey = 'coaching_tokens';
        amount = 100; // Deduct 100 tokens for coaching
        break;
    }
    
    // If no specific subscription ID, get the one with soonest end date
    let subId = subscriptionId;
    if (!subId) {
      const subsResult = await pool.query(`
        SELECT subscription_id FROM get_user_active_subscriptions($1)
        WHERE (credits_remaining->$2)::INTEGER > 0
        LIMIT 1
      `, [userId, creditKey]);
      
      if (subsResult.rows.length === 0) {
        return res.status(400).json({ error: 'No available credits' });
      }
      
      subId = subsResult.rows[0].subscription_id;
    }
    
    // Update credits
    const result = await pool.query(`
      SELECT update_subscription_credits($1, $2, $3) as success
    `, [subId, creditKey, amount]);
    
    if (!result.rows[0].success) {
      return res.status(400).json({ error: 'Insufficient credits' });
    }
    
    res.json({
      success: true,
      message: 'Credits used successfully',
      subscriptionId: subId
    });
  } catch (error) {
    console.error('Error using credits:', error);
    res.status(500).json({ error: 'Failed to use credits' });
  }
});

export default router;
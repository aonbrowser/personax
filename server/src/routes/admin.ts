import { Router, Request, Response } from 'express';
import { pool } from '../db/pool';

const router = Router();

// Middleware to check admin auth (implement proper auth later)
const requireAdmin = (req: Request, res: Response, next: Function) => {
  // TODO: Implement proper admin authentication
  // For now, check for admin header
  const adminKey = req.headers['x-admin-key'];
  if (adminKey !== 'admin-secret-key-2025') {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
};

// Get all subscription plans
router.get('/pricing/plans', requireAdmin, async (req: Request, res: Response) => {
  try {
    const result = await pool.query(`
      SELECT * FROM subscription_plans 
      WHERE is_active = true 
      ORDER BY price_usd ASC
    `);
    res.json({ plans: result.rows });
  } catch (error) {
    console.error('Error fetching plans:', error);
    res.status(500).json({ error: 'Failed to fetch plans' });
  }
});

// Update subscription plan
router.put('/pricing/plans/:planId', requireAdmin, async (req: Request, res: Response) => {
  const { planId } = req.params;
  const {
    name,
    total_analysis_credits,
    coaching_tokens_limit,
    price_usd
  } = req.body;

  try {
    const result = await pool.query(`
      UPDATE subscription_plans 
      SET 
        name = COALESCE($2, name),
        total_analysis_credits = COALESCE($3, total_analysis_credits),
        coaching_tokens_limit = COALESCE($4, coaching_tokens_limit),
        price_usd = COALESCE($5, price_usd),
        self_analysis_limit = 1,
        self_reanalysis_limit = COALESCE($3, total_analysis_credits),
        other_analysis_limit = COALESCE($3, total_analysis_credits),
        relationship_analysis_limit = COALESCE($3, total_analysis_credits),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [planId, name, total_analysis_credits, coaching_tokens_limit, price_usd]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Plan not found' });
    }

    res.json({ plan: result.rows[0] });
  } catch (error) {
    console.error('Error updating plan:', error);
    res.status(500).json({ error: 'Failed to update plan' });
  }
});

// Get Pay As You Go pricing
router.get('/pricing/payg', requireAdmin, async (req: Request, res: Response) => {
  try {
    const result = await pool.query(`
      SELECT * FROM payg_pricing 
      WHERE is_active = true 
      ORDER BY service_type
    `);
    res.json({ pricing: result.rows });
  } catch (error) {
    console.error('Error fetching PAYG pricing:', error);
    res.status(500).json({ error: 'Failed to fetch PAYG pricing' });
  }
});

// Update PAYG pricing
router.put('/pricing/payg/:pricingId', requireAdmin, async (req: Request, res: Response) => {
  const { pricingId } = req.params;
  const { price_usd } = req.body;

  try {
    const result = await pool.query(`
      UPDATE payg_pricing 
      SET 
        price_usd = COALESCE($2, price_usd),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [pricingId, price_usd]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Pricing not found' });
    }

    res.json({ pricing: result.rows[0] });
  } catch (error) {
    console.error('Error updating PAYG pricing:', error);
    res.status(500).json({ error: 'Failed to update PAYG pricing' });
  }
});

// Get usage statistics
router.get('/usage/stats', requireAdmin, async (req: Request, res: Response) => {
  try {
    const { user_id, month } = req.query;
    
    let query = `
      SELECT 
        mus.*,
        u.email,
        us.plan_id,
        sp.name as plan_name
      FROM monthly_usage_summary mus
      LEFT JOIN users u ON mus.user_id = u.id
      LEFT JOIN user_subscriptions us ON mus.subscription_id = us.id
      LEFT JOIN subscription_plans sp ON us.plan_id = sp.id
      WHERE 1=1
    `;
    
    const params: any[] = [];
    
    if (user_id) {
      params.push(user_id);
      query += ` AND mus.user_id = $${params.length}`;
    }
    
    if (month) {
      params.push(month);
      query += ` AND mus.month_year = $${params.length}`;
    } else {
      // Default to current month
      const currentMonth = new Date().toISOString().slice(0, 7);
      params.push(currentMonth);
      query += ` AND mus.month_year = $${params.length}`;
    }
    
    query += ` ORDER BY mus.created_at DESC`;
    
    const result = await pool.query(query, params);
    res.json({ stats: result.rows });
  } catch (error) {
    console.error('Error fetching usage stats:', error);
    res.status(500).json({ error: 'Failed to fetch usage stats' });
  }
});

// Get detailed usage logs
router.get('/usage/logs', requireAdmin, async (req: Request, res: Response) => {
  try {
    const { user_id, service_type, limit = 100, offset = 0 } = req.query;
    
    let query = `
      SELECT 
        ut.*,
        u.email
      FROM usage_tracking ut
      LEFT JOIN users u ON ut.user_id = u.id
      WHERE 1=1
    `;
    
    const params: any[] = [];
    
    if (user_id) {
      params.push(user_id);
      query += ` AND ut.user_id = $${params.length}`;
    }
    
    if (service_type) {
      params.push(service_type);
      query += ` AND ut.service_type = $${params.length}`;
    }
    
    query += ` ORDER BY ut.created_at DESC`;
    
    params.push(limit);
    query += ` LIMIT $${params.length}`;
    
    params.push(offset);
    query += ` OFFSET $${params.length}`;
    
    const result = await pool.query(query, params);
    
    // Get total count for pagination
    let countQuery = `
      SELECT COUNT(*) as total
      FROM usage_tracking ut
      WHERE 1=1
    `;
    
    const countParams: any[] = [];
    
    if (user_id) {
      countParams.push(user_id);
      countQuery += ` AND ut.user_id = $${countParams.length}`;
    }
    
    if (service_type) {
      countParams.push(service_type);
      countQuery += ` AND ut.service_type = $${countParams.length}`;
    }
    
    const countResult = await pool.query(countQuery, countParams);
    
    res.json({ 
      logs: result.rows,
      total: parseInt(countResult.rows[0].total),
      limit: parseInt(limit as string),
      offset: parseInt(offset as string)
    });
  } catch (error) {
    console.error('Error fetching usage logs:', error);
    res.status(500).json({ error: 'Failed to fetch usage logs' });
  }
});

// Get token costs configuration
router.get('/pricing/token-costs', requireAdmin, async (req: Request, res: Response) => {
  try {
    const result = await pool.query(`
      SELECT * FROM token_costs 
      WHERE is_active = true 
      ORDER BY model_name
    `);
    res.json({ costs: result.rows });
  } catch (error) {
    console.error('Error fetching token costs:', error);
    res.status(500).json({ error: 'Failed to fetch token costs' });
  }
});

// Update token costs
router.put('/pricing/token-costs/:modelId', requireAdmin, async (req: Request, res: Response) => {
  const { modelId } = req.params;
  const { input_cost_per_1k, output_cost_per_1k } = req.body;

  try {
    const result = await pool.query(`
      UPDATE token_costs 
      SET 
        input_cost_per_1k = COALESCE($2, input_cost_per_1k),
        output_cost_per_1k = COALESCE($3, output_cost_per_1k),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [modelId, input_cost_per_1k, output_cost_per_1k]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Model costs not found' });
    }

    res.json({ costs: result.rows[0] });
  } catch (error) {
    console.error('Error updating token costs:', error);
    res.status(500).json({ error: 'Failed to update token costs' });
  }
});

// Get token packages
router.get('/token-packages', requireAdmin, async (req: Request, res: Response) => {
  try {
    const result = await pool.query(`
      SELECT * FROM token_packages 
      WHERE is_active = true 
      ORDER BY token_amount ASC
    `);
    res.json({ packages: result.rows });
  } catch (error) {
    console.error('Error fetching token packages:', error);
    res.status(500).json({ error: 'Failed to fetch token packages' });
  }
});

// Update token package
router.put('/token-packages/:packageId', requireAdmin, async (req: Request, res: Response) => {
  const { packageId } = req.params;
  const { price_usd } = req.body;

  try {
    const result = await pool.query(`
      UPDATE token_packages 
      SET 
        price_usd = COALESCE($2, price_usd),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
    `, [packageId, price_usd]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Package not found' });
    }

    res.json({ package: result.rows[0] });
  } catch (error) {
    console.error('Error updating token package:', error);
    res.status(500).json({ error: 'Failed to update token package' });
  }
});

// Dashboard summary
router.get('/dashboard', requireAdmin, async (req: Request, res: Response) => {
  try {
    const currentMonth = new Date().toISOString().slice(0, 7);
    
    // Get total users
    const usersResult = await pool.query('SELECT COUNT(*) as total FROM users');
    
    // Get active subscriptions
    const subsResult = await pool.query(`
      SELECT 
        plan_id,
        COUNT(*) as count
      FROM user_subscriptions
      WHERE status = 'active'
      GROUP BY plan_id
    `);
    
    // Get monthly revenue
    const revenueResult = await pool.query(`
      SELECT 
        SUM(total_charged_usd) as revenue,
        SUM(total_cost_usd) as cost
      FROM monthly_usage_summary
      WHERE month_year = $1
    `, [currentMonth]);
    
    // Get top users by usage
    const topUsersResult = await pool.query(`
      SELECT 
        u.email,
        mus.total_charged_usd,
        mus.coaching_tokens_used,
        mus.self_analysis_count + mus.other_analysis_count + mus.relationship_analysis_count as total_analyses
      FROM monthly_usage_summary mus
      JOIN users u ON mus.user_id = u.id
      WHERE mus.month_year = $1
      ORDER BY mus.total_charged_usd DESC
      LIMIT 10
    `, [currentMonth]);
    
    res.json({
      dashboard: {
        totalUsers: parseInt(usersResult.rows[0].total),
        activeSubscriptions: subsResult.rows,
        monthlyRevenue: parseFloat(revenueResult.rows[0]?.revenue || 0),
        monthlyCost: parseFloat(revenueResult.rows[0]?.cost || 0),
        topUsers: topUsersResult.rows,
        currentMonth
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard data' });
  }
});

export default router;
import { Router } from 'express';
import { runSelfAnalysis, runOtherAnalysis, runDyadReport, runCoach } from '../ai/pipeline.js';
import { pool } from '../db/pool.js';

export const router = Router();

router.get('/health', (_req, res)=> res.json({ ok: true }));

// Check if user has credits for a service
router.post('/user/check-credits', async (req, res) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const { serviceType } = req.body;
  
  // For now, always return true - you can implement actual subscription logic later
  // This should check the user's subscription status, credits, etc.
  res.json({
    hasCredits: true,
    creditsRemaining: 100, // Example
    subscriptionType: 'premium', // Example
  });
});

// Get items by form endpoint
router.get('/items/by-form', async (req, res) => {
  const form = String(req.query.form || '').trim();
  if (!form) {
    return res.status(400).json({ error: 'form query is required' });
  }
  
  console.log(`[DEBUG] Fetching items for form: ${form}`);
  
  try {
    const { rows } = await pool.query(
      `SELECT id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes 
       FROM items 
       WHERE form = $1 
       ORDER BY COALESCE(display_order, 99999), id`,
      [form]
    );
    console.log(`[DEBUG] Found ${rows.length} items for form: ${form}`);
    res.json({ items: rows });
  } catch (e) {
    console.error('Error fetching items by form:', e);
    res.status(500).json({ 
      error: 'db_error', 
      message: String(e) 
    });
  }
});

router.post('/analyze/self', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userIdHeader = req.header('x-user-id');
  const userEmail = req.header('x-user-email');
  const targetId = req.body.targetId || 'self';
  
  // CRITICAL: Require valid email
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - valid email required' });
  }
  
  // LOG: Print received data
  console.log('\n=== RECEIVED AT BACKEND ===');
  console.log('User Email:', userEmail);
  console.log('Request body keys:', Object.keys(req.body));
  
  // Check for new form structure
  if (req.body.form1 || req.body.form2 || req.body.form3) {
    console.log('NEW FORM STRUCTURE DETECTED!');
    
    // Validate form data is not empty
    const form1Count = req.body.form1 ? Object.keys(req.body.form1).length : 0;
    const form2Count = req.body.form2 ? Object.keys(req.body.form2).length : 0;
    const form3Count = req.body.form3 ? Object.keys(req.body.form3).length : 0;
    
    console.log('=== FORM DATA VALIDATION ===');
    console.log('Form1 responses:', form1Count);
    console.log('Form2 responses:', form2Count);
    console.log('Form3 responses:', form3Count);
    
    // Check if all forms are empty
    if (form1Count === 0 && form2Count === 0 && form3Count === 0) {
      console.error('ERROR: All forms are empty!');
      return res.status(400).json({
        error: 'empty_forms',
        message: 'Tüm formlar boş. Lütfen en az bir formu doldurun.',
        details: {
          form1: form1Count,
          form2: form2Count,
          form3: form3Count
        }
      });
    }
    
    // Check if Form1 (demographics) has minimum required fields
    if (form1Count > 0 && form1Count < 3) {
      console.warn('WARNING: Form1 has very few responses:', form1Count);
      // Not blocking, just warning
    }
    
    if (req.body.form1) {
      console.log('Form1 keys received:', Object.keys(req.body.form1));
      console.log('Form1 sample values:', {
        age: req.body.form1.F1_AGE,
        gender: req.body.form1.F1_GENDER,
        relationship: req.body.form1.F1_RELATIONSHIP,
        education: req.body.form1.F1_EDUCATION
      });
    }
    if (req.body.form2) {
      console.log('Form2 keys received:', Object.keys(req.body.form2).length, 'total');
      console.log('Form2 sample keys:', Object.keys(req.body.form2).slice(0, 5));
    }
    if (req.body.form3) {
      console.log('Form3 keys received:', Object.keys(req.body.form3).length, 'total');
      console.log('Form3 sample keys:', Object.keys(req.body.form3).slice(0, 5));
    }
  } else if (req.body.s0 || req.body.s1) {
    console.log('OLD S0/S1 STRUCTURE');
    if (req.body.s0) {
      console.log('S0 keys received:', Object.keys(req.body.s0));
      console.log('S0 sample values:', {
        age: req.body.s0.S0_AGE,
        gender: req.body.s0.S0_GENDER,
        lifeGoal: req.body.s0.S0_LIFE_GOAL?.substring(0, 50),
        happyMemory: req.body.s0.S0_HAPPY_MEMORY?.substring(0, 50)
      });
    }
    if (req.body.s1) {
      console.log('S1 keys received:', Object.keys(req.body.s1).slice(0, 10), '...');
    }
  } else {
    console.log('WARNING: No recognized form structure in request body!');
  }
  console.log('===========================\n');
  
  // Get user UUID - check if header is already a UUID or email
  let userId: string;
  
  // Check if x-user-id is a valid UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (userIdHeader && uuidRegex.test(userIdHeader)) {
    userId = userIdHeader;
  } else if (userEmail && userEmail.includes('@')) {
    // Try to get user by email
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userResult.rows.length > 0) {
      userId = userResult.rows[0].id;
    } else {
      // Create a new user if doesn't exist
      const newUserResult = await pool.query(
        'INSERT INTO users (email) VALUES ($1) RETURNING id',
        [userEmail]
      );
      userId = newUserResult.rows[0].id;
    }
  } else {
    // CRITICAL: No fallback to test user - this is a security risk
    return res.status(401).json({ 
      error: 'Unauthorized - valid email required',
      message: 'User email is required for analysis'
    });
  }
  
  // Log the exact data being passed to pipeline
  // Check if this is an update to existing analysis
  const analysisId = req.body.analysisId;
  const updateExisting = req.body.updateExisting;
  
  if (updateExisting && analysisId) {
    console.log('[ROUTE] Updating existing analysis:', analysisId);
    
    // Verify the analysis belongs to this user
    const analysisCheck = await pool.query(
      'SELECT id FROM analysis_results WHERE id = $1 AND user_id = $2',
      [analysisId, userId]
    );
    
    if (analysisCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Analysis not found or unauthorized' });
    }
  }
  
  console.log('[ROUTE] Passing to runSelfAnalysis:');
  console.log('- Body keys:', Object.keys(req.body));
  if (req.body.form1) console.log('- Form1 sample:', Object.keys(req.body.form1).slice(0, 3));
  if (req.body.form2) console.log('- Form2 sample:', Object.keys(req.body.form2).slice(0, 3));
  if (req.body.form3) console.log('- Form3 sample:', Object.keys(req.body.form3).slice(0, 3));
  
  const r = await runSelfAnalysis(req.body, lang, userId, targetId, analysisId);
  res.json(r);
});

router.post('/analyze/other', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  const targetId = req.body.targetId || req.body.personName || 'unknown'; // Person being analyzed
  const r = await runOtherAnalysis(req.body, lang, userId, targetId);
  res.json(r);
});

router.post('/analyze/dyad', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  // For dyad, targetId could be combination of two person IDs
  const targetId = req.body.targetId || `${req.body.person1Name}-${req.body.person2Name}` || 'dyad';
  const r = await runDyadReport(req.body, lang, userId, targetId);
  res.json(r);
});

router.post('/coach', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  const r = await runCoach(req.body, lang, userId);
  res.json(r);
});

// Get saved form responses for an analysis
router.get('/user/analyses/:id/responses', async (req, res) => {
  const userEmail = req.header('x-user-email');
  const analysisId = req.params.id;
  
  // Validate email
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - invalid email' });
  }
  
  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(analysisId)) {
    return res.status(400).json({ error: 'Invalid analysis ID format' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Fetch responses - verify user ownership
    const result = await pool.query(
      `SELECT fr.item_id, fr.response_value, fr.response_label, fr.response_type, 
              fr.disc_most, fr.disc_least, fr.form
       FROM form_responses fr
       WHERE fr.analysis_id = $1 AND fr.user_id = $2
       ORDER BY fr.form, fr.item_id`,
      [analysisId, userId]
    );
    
    // Group responses by form
    const responsesByForm = {
      form1: {} as any,
      form2: {} as any,
      form3: {} as any
    };
    
    result.rows.forEach(row => {
      const formKey = row.form === 'Form1_Tanisalim' ? 'form1' :
                     row.form === 'Form2_Kisilik' ? 'form2' :
                     row.form === 'Form3_Davranis' ? 'form3' : null;
      
      if (formKey) {
        // Parse JSON values if needed
        let value = row.response_value;
        try {
          if (value && (value.startsWith('[') || value.startsWith('{'))) {
            value = JSON.parse(value);
          }
        } catch (e) {
          // Keep as string if not valid JSON
        }
        
        // For DISC questions, include both most and least
        if (row.response_type === 'DISC' && row.disc_most !== null && row.disc_least !== null) {
          responsesByForm[formKey][row.item_id] = {
            most: row.disc_most,
            least: row.disc_least
          };
        } else {
          responsesByForm[formKey][row.item_id] = value;
        }
      }
    });
    
    res.json({ 
      success: true,
      responses: responsesByForm,
      totalResponses: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching form responses:', error);
    res.status(500).json({ error: 'Failed to fetch responses' });
  }
});

// Simple admin endpoint for language incidents (paged)
router.get('/admin/language-incidents', async (req, res) => {
  const limit = Math.max(1, Math.min(Number(req.query.limit)||50, 200));
  const { rows } = await pool.query(`SELECT id, user_id, report_type, user_language, detected_language, content_preview, created_at
                                     FROM language_incidents ORDER BY created_at DESC LIMIT $1`, [limit]);
  res.json({ items: rows });
});

// Get user's usage summary
router.get('/user/usage', async (req, res) => {
  const userId = req.header('x-user-id') || 'anon';
  const { UsageTracker } = await import('../services/usage-tracker.js');
  const summary = await UsageTracker.getUserUsageSummary(userId);
  res.json({ usage: summary });
});

// Get user's analyses
router.get('/user/analyses', async (req, res) => {
  const userEmail = req.header('x-user-email');
  
  // CRITICAL SECURITY: Never use default email
  if (!userEmail || !userEmail.includes('@')) {
    console.error('SECURITY: No valid email provided for analyses request');
    return res.json({ analyses: [] });
  }
  
  // Get user ID from email
  let userId = null;
  const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
  if (userResult.rows.length > 0) {
    userId = userResult.rows[0].id;
  }
  
  if (!userId) {
    console.log('User not found for email:', userEmail);
    return res.json({ analyses: [] });
  }
  
  try {
    // First, update any processing analyses older than 8 minutes to error status
    // Check against updated_at for retried/updated analyses, fall back to created_at for new ones
    await pool.query(
      `UPDATE analysis_results 
       SET status = 'error', 
           error_message = 'Analysis timed out after 8 minutes'
       WHERE user_id = $1 
         AND status = 'processing' 
         AND COALESCE(updated_at, created_at) < NOW() - INTERVAL '8 minutes'`,
      [userId]
    );
    
    // Then fetch all analyses
    const { rows } = await pool.query(
      `SELECT id, analysis_type, status, result_markdown, result_blocks, error_message, 
              created_at, updated_at, completed_at, s0_data, s1_data
       FROM analysis_results 
       WHERE user_id = $1 
       ORDER BY created_at DESC 
       LIMIT 50`,
      [userId]
    );
    res.json({ analyses: rows });
  } catch (error) {
    console.error('Error fetching analyses:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

// Delete analysis
// Generate PDF endpoint
router.post('/generate-pdf', async (req, res) => {
  const { markdown } = req.body;
  
  if (!markdown) {
    return res.status(400).json({ error: 'Markdown content is required' });
  }
  
  try {
    // Call Python PDF service
    const response = await fetch('http://localhost:5000/generate-pdf', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ markdown }),
    });
    
    if (!response.ok) {
      throw new Error('PDF generation failed');
    }
    
    const result = await response.json();
    
    if (result.success && result.pdf) {
      // Return PDF as base64
      res.json({
        success: true,
        pdf: result.pdf,
        filename: result.filename
      });
    } else {
      throw new Error(result.error || 'PDF generation failed');
    }
  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).json({ 
      error: 'PDF generation failed',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// SECURE: Get single analysis result with user verification
router.get('/user/analyses/:id', async (req, res) => {
  const userEmail = req.header('x-user-email');
  const analysisId = req.params.id;
  
  // Validate email
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - invalid email' });
  }
  
  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(analysisId)) {
    return res.status(400).json({ error: 'Invalid analysis ID format' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // CRITICAL: Verify that this analysis belongs to this user
    const result = await pool.query(
      `SELECT id, analysis_type, status, result_markdown, result_blocks, error_message,
              created_at, updated_at, completed_at, form1_data, form2_data, form3_data
       FROM analysis_results 
       WHERE id = $1 AND user_id = $2`,
      [analysisId, userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Analysis not found or unauthorized' });
    }
    
    res.json({ analysis: result.rows[0] });
  } catch (error) {
    console.error('Error fetching analysis:', error);
    res.status(500).json({ error: 'Failed to fetch analysis' });
  }
});

// Get analysis responses for editing
router.get('/analyses/:id/responses', async (req, res) => {
  const userEmail = req.header('x-user-email');
  const analysisId = req.params.id;
  
  // Validate email
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - invalid email' });
  }
  
  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(analysisId)) {
    return res.status(400).json({ error: 'Invalid analysis ID format' });
  }
  
  try {
    // Get user ID from email
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'User not found' });
    }
    
    const userId = userResult.rows[0].id;
    
    // Get the analysis and verify ownership
    const result = await pool.query(
      `SELECT form1_data, form2_data, form3_data 
       FROM analysis_results 
       WHERE id = $1 AND user_id = $2`,
      [analysisId, userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Analysis not found or unauthorized' });
    }
    
    const analysis = result.rows[0];
    
    res.json({
      form1Data: analysis.form1_data || {},
      form2Data: analysis.form2_data || {},
      form3Data: analysis.form3_data || {}
    });
  } catch (error) {
    console.error('Error fetching analysis responses:', error);
    res.status(500).json({ error: 'Failed to fetch analysis responses' });
  }
});

router.delete('/user/analyses/:id', async (req, res) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const analysisId = req.params.id;
  
  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(analysisId)) {
    console.log('Invalid UUID format:', analysisId);
    return res.status(400).json({ error: 'Invalid analysis ID format' });
  }
  
  // Get user ID from email
  let userId = null;
  if (userEmail && userEmail.includes('@')) {
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userResult.rows.length > 0) {
      userId = userResult.rows[0].id;
    }
  }
  
  if (!userId) {
    return res.status(401).json({ error: 'User not found' });
  }
  
  try {
    const result = await pool.query(
      'DELETE FROM analysis_results WHERE id = $1 AND user_id = $2 RETURNING id',
      [analysisId, userId]
    );
    
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Analysis not found or unauthorized' });
    }
    
    res.json({ success: true, message: 'Analysis deleted' });
  } catch (error) {
    console.error('Error deleting analysis:', error);
    res.status(500).json({ error: 'Failed to delete analysis' });
  }
});

// Retry analysis
router.post('/analyze/retry', async (req, res) => {
  const userEmail = req.header('x-user-email');
  
  if (!userEmail || !userEmail.includes('@')) {
    return res.status(401).json({ error: 'Unauthorized - email required' });
  }
  const { analysisId } = req.body;
  
  if (!analysisId) {
    return res.status(400).json({ error: 'Analysis ID required' });
  }
  
  // Get user ID from email
  let userId = null;
  if (userEmail && userEmail.includes('@')) {
    const userResult = await pool.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userResult.rows.length > 0) {
      userId = userResult.rows[0].id;
    }
  }
  
  if (!userId) {
    return res.status(401).json({ error: 'User not found' });
  }
  
  try {
    // Get the failed analysis
    const { rows } = await pool.query(
      `SELECT * FROM analysis_results 
       WHERE id = $1 AND user_id = $2 AND status = 'error'`,
      [analysisId, userId]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Analysis not found or cannot be retried' });
    }
    
    const analysis = rows[0];
    
    // Update status to processing
    await pool.query(
      `UPDATE analysis_results 
       SET status = 'processing', retry_count = retry_count + 1 
       WHERE id = $1`,
      [analysisId]
    );
    
    // Re-run the analysis in background
    const lang = (req.header('x-user-lang') || 'tr').toLowerCase();
    
    // Combine S0 and S1 data
    const combinedData = {
      s0: analysis.s0_data,
      s1: analysis.s1_data
    };
    
    // Run analysis asynchronously
    runSelfAnalysis(combinedData, lang, userId, 'self').then(async (result) => {
      // Update with result
      await pool.query(
        `UPDATE analysis_results 
         SET status = 'completed', 
             result_markdown = $1, 
             lifecoaching_notes = $2,
             completed_at = NOW() 
         WHERE id = $3`,
        [result.markdown, result.lifecoachingNotes, analysisId]
      );
    }).catch(async (error) => {
      // Update with error
      await pool.query(
        `UPDATE analysis_results 
         SET status = 'error', 
             error_message = $1 
         WHERE id = $2`,
        [error.message || 'Analysis failed', analysisId]
      );
    });
    
    res.json({ success: true, message: 'Analysis retry started' });
  } catch (error) {
    console.error('Error retrying analysis:', error);
    res.status(500).json({ error: 'Failed to retry analysis' });
  }
});

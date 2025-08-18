import { Router } from 'express';
import { runSelfAnalysis, runOtherAnalysis, runDyadReport, runCoach } from '../ai/pipeline.js';
import { pool } from '../db/pool.js';

export const router = Router();

router.get('/health', (_req, res)=> res.json({ ok: true }));

// Get items by form endpoint
router.get('/v1/items/by-form', async (req, res) => {
  const form = String(req.query.form || '').trim();
  if (!form) {
    return res.status(400).json({ error: 'form query is required' });
  }
  
  try {
    const { rows } = await pool.query(
      `SELECT id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes 
       FROM items 
       WHERE form = $1 
       ORDER BY COALESCE(display_order, 99999), id`,
      [form]
    );
    res.json({ items: rows });
  } catch (e) {
    console.error('Error fetching items by form:', e);
    res.status(500).json({ 
      error: 'db_error', 
      message: String(e) 
    });
  }
});

router.post('/v1/analyze/self', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  const r = await runSelfAnalysis(req.body, lang, userId);
  res.json(r);
});

router.post('/v1/analyze/other', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  const r = await runOtherAnalysis(req.body, lang, userId);
  res.json(r);
});

router.post('/v1/analyze/dyad', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  const r = await runDyadReport(req.body, lang, userId);
  res.json(r);
});

router.post('/v1/coach', async (req, res) => {
  const lang = (req.header('x-user-lang') || 'en').toLowerCase();
  const userId = req.header('x-user-id') || 'anon';
  const r = await runCoach(req.body, lang, userId);
  res.json(r);
});

// Simple admin endpoint for language incidents (paged)
router.get('/v1/admin/language-incidents', async (req, res) => {
  const limit = Math.max(1, Math.min(Number(req.query.limit)||50, 200));
  const { rows } = await pool.query(`SELECT id, user_id, report_type, user_language, detected_language, content_preview, created_at
                                     FROM language_incidents ORDER BY created_at DESC LIMIT $1`, [limit]);
  res.json({ items: rows });
});

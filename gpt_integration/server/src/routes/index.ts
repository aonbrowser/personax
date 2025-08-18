import express from 'express';
import cors from 'cors';
import { ENV } from '../config/env.js';
import { pool } from '../db/pool.js';

export const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res)=> res.json({ ok:true }));

app.get('/v1/items/by-form', async (req, res) => {
  const form = String(req.query.form||'').trim();
  if (!form) return res.status(400).json({ error: 'form query is required' });
  try {
    const { rows } = await pool.query(
      `SELECT id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes
       FROM items WHERE form=$1 ORDER BY id`, [form]
    );
    res.json({ items: rows });
  } catch (e) {
    res.status(500).json({ error: 'db_error', message: String(e) });
  }
});

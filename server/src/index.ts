import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import { ENV } from './config/env.js';
import { router } from './routes/index.js';
import adminRouter from './routes/admin.js';
import paymentRouter from './routes/payment.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, x-user-lang, x-user-id, x-user-email, x-admin-key');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

app.use(express.json({ limit: '2mb' }));

// Serve admin panel static files
app.use('/admin', express.static(path.join(__dirname, 'admin')));

// Admin panel route
app.get('/stargate', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin', 'index.html'));
});

// Prompt files route (read-only)
app.get('/admin/prompts/:type.md', (req, res) => {
  const promptType = req.params.type;
  const allowedTypes = ['self', 'other', 'dyad', 'coach'];
  
  if (allowedTypes.includes(promptType)) {
    res.sendFile(path.join(__dirname, 'prompts', `${promptType}.md`));
  } else {
    res.status(404).send('Prompt not found');
  }
});

// Prompt save route
app.put('/admin/prompts/:type', express.text(), async (req, res) => {
  const promptType = req.params.type;
  const content = req.body;
  const token = req.headers['x-admin-token'];
  
  // Simple token validation
  if (!token || !token.startsWith('Capitano:')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  const allowedTypes = ['self', 'other', 'dyad', 'coach'];
  if (!allowedTypes.includes(promptType)) {
    return res.status(400).json({ error: 'Invalid prompt type' });
  }
  
  try {
    const fs = await import('fs');
    const promptPath = path.join(__dirname, 'prompts', `${promptType}.md`);
    await fs.promises.writeFile(promptPath, content, 'utf-8');
    res.json({ success: true });
  } catch (error) {
    console.error('Error saving prompt:', error);
    res.status(500).json({ error: 'Failed to save prompt' });
  }
});

app.use('/v1', router);
app.use('/v1/admin', adminRouter);
app.use('/v1/payment', paymentRouter);

app.listen(ENV.PORT, ()=> console.log(`[server] listening on :${ENV.PORT}`));

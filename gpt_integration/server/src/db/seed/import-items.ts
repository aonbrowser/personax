import { pool } from '../pool.js';
import fs from 'node:fs';
import { parse } from 'csv-parse/sync';

const csvPath = process.argv[2];
if (!csvPath) { console.error('Usage: seed:items <file.csv>'); process.exit(1); }

const csv = fs.readFileSync(csvPath, 'utf8');
const rows = parse(csv, { columns: true, skip_empty_lines: true });

const client = await pool.connect();
await client.query('BEGIN');
for (const r of rows) {
  await client.query(
    `INSERT INTO items(id,form,section,subscale,text_tr,type,options_tr,reverse_scored,scoring_key,weight,notes)
     VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
     ON CONFLICT(id) DO UPDATE SET
       form=EXCLUDED.form, section=EXCLUDED.section, subscale=EXCLUDED.subscale, text_tr=EXCLUDED.text_tr,
       type=EXCLUDED.type, options_tr=EXCLUDED.options_tr, reverse_scored=EXCLUDED.reverse_scored,
       scoring_key=EXCLUDED.scoring_key, weight=EXCLUDED.weight, notes=EXCLUDED.notes`,
    [r.id, r.form, r.section, r.subscale, r.text_tr, r.type, r.options_tr, Number(r.reverse_scored||0), r.scoring_key||'', Number(r.weight||1), r.notes||'']
  );
}
await client.query('COMMIT'); client.release();
console.log('Imported', rows.length);

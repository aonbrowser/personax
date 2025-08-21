import { pool } from '../pool.js';
import fs from 'node:fs';
import path from 'node:path';
import { parse } from 'csv-parse/sync';

const csvPath = process.argv[2] || path.resolve(process.cwd(), 'data', 'testbank.csv');
const csv = fs.readFileSync(csvPath, 'utf8');
const rows = parse(csv, { columns: true, skip_empty_lines: true });

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const r of rows) {
      await client.query(
        `INSERT INTO items (id,form,section,test_type,subscale,text_en,text_tr,type,options_en,options_tr,reverse_scored,scoring_key,weight,notes,display_order)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
         ON CONFLICT (id) DO UPDATE SET
           form=EXCLUDED.form, section=EXCLUDED.section, test_type=EXCLUDED.test_type, subscale=EXCLUDED.subscale,
           text_en=EXCLUDED.text_en, text_tr=EXCLUDED.text_tr, type=EXCLUDED.type, 
           options_en=EXCLUDED.options_en, options_tr=EXCLUDED.options_tr,
           reverse_scored=EXCLUDED.reverse_scored, scoring_key=EXCLUDED.scoring_key,
           weight=EXCLUDED.weight, notes=EXCLUDED.notes, display_order=EXCLUDED.display_order`,
        [
          r.id, 
          r.form, 
          r.section, 
          r.test_type||null,
          r.subscale, 
          r.text_en||null,
          r.text_tr, 
          r.type, 
          r.options_en||null,
          r.options_tr, 
          r.reverse_scored === 'true' || r.reverse_scored === '1' ? 1 : 0,
          r.scoring_key||null, 
          Number(r.weight||1), 
          r.notes||null,
          r.display_order ? Number(r.display_order) : null
        ]
      );
    }
    await client.query('COMMIT');
    console.log(`Imported ${rows.length} items from ${csvPath}`);
  } catch (e) {
    await client.query('ROLLBACK');
    console.error(e);
    process.exit(1);
  } finally {
    client.release();
  }
}
main();

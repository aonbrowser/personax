import fs from 'node:fs';
import path from 'node:path';
import { retryEnforceLanguage } from './providers/openai.js';
import { pool } from '../db/pool.js';

function loadPrompt(file:string) {
  const p = path.resolve(process.cwd(), 'server', 'src', 'prompts', file);
  return fs.readFileSync(p, 'utf8');
}

async function logLanguageIncident(params: {
  user_id: string; report_type:'self'|'other'|'dyad'|'coach';
  user_language: string; detected_language: string; content_preview: string;
}) {
  await pool.query(
    `INSERT INTO language_incidents (user_id, report_type, user_language, detected_language, content_preview)
     VALUES ($1,$2,$3,$4,$5)`,
    [params.user_id, params.report_type, params.user_language, params.detected_language, params.content_preview.slice(0,500)]
  );
}

type Msg = { role:'system'|'user'|'assistant', content:string };

export async function runSelfAnalysis(payload:any, userLang:string, userId:string) {
  const sys = loadPrompt('self.md');
  const messages: Msg[] = [ { role:'system', content: sys }, { role:'user', content: `INPUT JSON:\n${JSON.stringify(payload)}` } ];
  const { content, ok, detected } = await retryEnforceLanguage(messages, userLang, 2);
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'self', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}

export async function runOtherAnalysis(payload:any, userLang:string, userId:string) {
  const sys = loadPrompt('other.md');
  const messages: Msg[] = [ { role:'system', content: sys }, { role:'user', content: `INPUT JSON:\n${JSON.stringify(payload)}` } ];
  const { content, ok, detected } = await retryEnforceLanguage(messages, userLang, 2);
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'other', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}

export async function runDyadReport(payload:any, userLang:string, userId:string) {
  const sys = loadPrompt('dyad.md');
  const messages: Msg[] = [ { role:'system', content: sys }, { role:'user', content: `INPUT JSON:\n${JSON.stringify(payload)}` } ];
  const { content, ok, detected } = await retryEnforceLanguage(messages, userLang, 2);
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'dyad', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}

export async function runCoach(payload:any, userLang:string, userId:string) {
  const sys = loadPrompt('coach.md');
  const messages: Msg[] = [ { role:'system', content: sys }, { role:'user', content: `INPUT JSON:\n${JSON.stringify(payload)}` } ];
  const { content, ok, detected } = await retryEnforceLanguage(messages, userLang, 2);
  if (!ok) await logLanguageIncident({ user_id:userId, report_type:'coach', user_language:userLang, detected_language:detected, content_preview:content.slice(0,400) });
  const banner = ok ? null : "Bu rapor sizin dilinizde değil gibi görünüyor. Sistem yöneticilerimiz durumdan haberdar edildi. En yakın zamanda kendi dilinizde rapor vereceğiz.";
  return { markdown: content, language_ok: ok, detected, banner };
}

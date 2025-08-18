import OpenAI from 'openai';
import { ENV } from '../../config/env.js';

export const openai = new OpenAI({ apiKey: ENV.OPENAI_API_KEY });

export async function chatCompletionHigh(messages: Array<{role:'system'|'user'|'assistant', content:string}>) {
  const res = await openai.chat.completions.create({
    model: 'gpt-5-high',
    messages,
    temperature: 0.4,
  });
  return res.choices[0]?.message?.content ?? '';
}

export async function detectLanguageWithMini(text: string, expectedLang: string) {
  const sys = `You are a strict language detector. Output exactly one word: MATCH if the provided text is in ${expectedLang} (allow proper nouns), else MISMATCH:<iso_or_name>.`;
  const res = await openai.chat.completions.create({
    model: 'gpt-5-mini',
    temperature: 0,
    messages: [
      { role: 'system', content: sys },
      { role: 'user', content: text.slice(0, 2000) }
    ]
  });
  const out = res.choices[0]?.message?.content?.trim() ?? '';
  if (out.startsWith('MATCH')) return { ok: true, detected: expectedLang };
  if (out.startsWith('MISMATCH:')) return { ok: false, detected: out.split(':',2)[1] || 'unknown' };
  return { ok: text.length>0, detected: expectedLang };
}

export async function retryEnforceLanguage(messages: Array<{role:'system'|'user'|'assistant', content:string}>, userLang: string, maxTries=2) {
  let content = await chatCompletionHigh(messages);
  let check = await detectLanguageWithMini(content, userLang);
  let tries = 0;
  while (!check.ok && tries < maxTries) {
    const feedback = `Bu çıktı kullanıcının dili (${userLang}) ile eşleşmiyor. Lütfen **aynı içeriği**, yalnızca ${userLang} dilinde üret.`;
    const newMsgs = [...messages, { role:'assistant', content }, { role:'user', content: feedback }];
    content = await chatCompletionHigh(newMsgs);
    check = await detectLanguageWithMini(content, userLang);
    tries++;
  }
  return { content, ok: check.ok, detected: check.detected };
}

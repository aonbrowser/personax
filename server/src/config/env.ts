import 'dotenv/config';
export const ENV = {
  NODE_ENV: process.env.NODE_ENV ?? 'development',
  PORT: Number(process.env.PORT ?? 8080),
  DATABASE_URL: process.env.DATABASE_URL ?? '',
  OPENAI_API_KEY: process.env.OPENAI_API_KEY ?? '',
  DEFAULT_LOCALE: process.env.DEFAULT_LOCALE ?? 'en',
  SUPPORTED_LOCALES: (process.env.SUPPORTED_LOCALES ?? 'en,es,fr,de,it,pt,nl,ru,zh,zh-TW,ja,ko,ar,tr,hi').split(','),
  LANG_CHECK: process.env.LANG_CHECK === 'true' // Only true if explicitly set to 'true'
};
if (!ENV.DATABASE_URL) console.warn('[WARN] DATABASE_URL missing');
if (!ENV.OPENAI_API_KEY) console.warn('[WARN] OPENAI_API_KEY missing');

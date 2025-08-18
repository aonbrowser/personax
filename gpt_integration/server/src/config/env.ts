import 'dotenv/config';
export const ENV = {
  PORT: Number(process.env.PORT || 8080),
  DATABASE_URL: String(process.env.DATABASE_URL || ''),
  OPENAI_API_KEY: String(process.env.OPENAI_API_KEY || ''),
};

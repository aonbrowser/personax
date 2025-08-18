-- Migration: Add multi-language support
-- This migration adds columns for supporting 15+ languages

-- Add text columns for all supported languages to items table
ALTER TABLE items 
  ADD COLUMN IF NOT EXISTS text_en TEXT,
  ADD COLUMN IF NOT EXISTS text_es TEXT,
  ADD COLUMN IF NOT EXISTS text_fr TEXT,
  ADD COLUMN IF NOT EXISTS text_de TEXT,
  ADD COLUMN IF NOT EXISTS text_it TEXT,
  ADD COLUMN IF NOT EXISTS text_pt TEXT,
  ADD COLUMN IF NOT EXISTS text_nl TEXT,
  ADD COLUMN IF NOT EXISTS text_ru TEXT,
  ADD COLUMN IF NOT EXISTS text_zh TEXT,
  ADD COLUMN IF NOT EXISTS text_zh_tw TEXT,
  ADD COLUMN IF NOT EXISTS text_ja TEXT,
  ADD COLUMN IF NOT EXISTS text_ko TEXT,
  ADD COLUMN IF NOT EXISTS text_ar TEXT,
  ADD COLUMN IF NOT EXISTS text_hi TEXT;

-- Add options columns for all supported languages to items table  
ALTER TABLE items
  ADD COLUMN IF NOT EXISTS options_en TEXT,
  ADD COLUMN IF NOT EXISTS options_es TEXT,
  ADD COLUMN IF NOT EXISTS options_fr TEXT,
  ADD COLUMN IF NOT EXISTS options_de TEXT,
  ADD COLUMN IF NOT EXISTS options_it TEXT,
  ADD COLUMN IF NOT EXISTS options_pt TEXT,
  ADD COLUMN IF NOT EXISTS options_nl TEXT,
  ADD COLUMN IF NOT EXISTS options_ru TEXT,
  ADD COLUMN IF NOT EXISTS options_zh TEXT,
  ADD COLUMN IF NOT EXISTS options_zh_tw TEXT,
  ADD COLUMN IF NOT EXISTS options_ja TEXT,
  ADD COLUMN IF NOT EXISTS options_ko TEXT,
  ADD COLUMN IF NOT EXISTS options_ar TEXT,
  ADD COLUMN IF NOT EXISTS options_hi TEXT;

-- Create index for faster locale-based queries
CREATE INDEX IF NOT EXISTS idx_users_locale ON users(locale);

-- Add default locale if not present
UPDATE users SET locale = 'en' WHERE locale IS NULL;

-- Create a function for localized item access
CREATE OR REPLACE FUNCTION get_localized_items(locale_code VARCHAR(10))
RETURNS TABLE (
  id TEXT,
  form TEXT,
  section TEXT,
  subscale TEXT,
  text TEXT,
  options TEXT,
  type TEXT,
  reverse_scored INTEGER,
  scoring_key TEXT,
  weight REAL,
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.id,
    i.form,
    i.section,
    i.subscale,
    CASE locale_code
      WHEN 'en' THEN COALESCE(i.text_en, i.text_tr)
      WHEN 'es' THEN COALESCE(i.text_es, i.text_en, i.text_tr)
      WHEN 'fr' THEN COALESCE(i.text_fr, i.text_en, i.text_tr)
      WHEN 'de' THEN COALESCE(i.text_de, i.text_en, i.text_tr)
      WHEN 'it' THEN COALESCE(i.text_it, i.text_en, i.text_tr)
      WHEN 'pt' THEN COALESCE(i.text_pt, i.text_en, i.text_tr)
      WHEN 'nl' THEN COALESCE(i.text_nl, i.text_en, i.text_tr)
      WHEN 'ru' THEN COALESCE(i.text_ru, i.text_en, i.text_tr)
      WHEN 'zh' THEN COALESCE(i.text_zh, i.text_en, i.text_tr)
      WHEN 'zh-tw' THEN COALESCE(i.text_zh_tw, i.text_en, i.text_tr)
      WHEN 'ja' THEN COALESCE(i.text_ja, i.text_en, i.text_tr)
      WHEN 'ko' THEN COALESCE(i.text_ko, i.text_en, i.text_tr)
      WHEN 'ar' THEN COALESCE(i.text_ar, i.text_en, i.text_tr)
      WHEN 'tr' THEN COALESCE(i.text_tr, i.text_en)
      WHEN 'hi' THEN COALESCE(i.text_hi, i.text_en, i.text_tr)
      ELSE COALESCE(i.text_en, i.text_tr)
    END AS text,
    CASE locale_code
      WHEN 'en' THEN COALESCE(i.options_en, i.options_tr)
      WHEN 'es' THEN COALESCE(i.options_es, i.options_en, i.options_tr)
      WHEN 'fr' THEN COALESCE(i.options_fr, i.options_en, i.options_tr)
      WHEN 'de' THEN COALESCE(i.options_de, i.options_en, i.options_tr)
      WHEN 'it' THEN COALESCE(i.options_it, i.options_en, i.options_tr)
      WHEN 'pt' THEN COALESCE(i.options_pt, i.options_en, i.options_tr)
      WHEN 'nl' THEN COALESCE(i.options_nl, i.options_en, i.options_tr)
      WHEN 'ru' THEN COALESCE(i.options_ru, i.options_en, i.options_tr)
      WHEN 'zh' THEN COALESCE(i.options_zh, i.options_en, i.options_tr)
      WHEN 'zh-tw' THEN COALESCE(i.options_zh_tw, i.options_en, i.options_tr)
      WHEN 'ja' THEN COALESCE(i.options_ja, i.options_en, i.options_tr)
      WHEN 'ko' THEN COALESCE(i.options_ko, i.options_en, i.options_tr)
      WHEN 'ar' THEN COALESCE(i.options_ar, i.options_en, i.options_tr)
      WHEN 'tr' THEN COALESCE(i.options_tr, i.options_en)
      WHEN 'hi' THEN COALESCE(i.options_hi, i.options_en, i.options_tr)
      ELSE COALESCE(i.options_en, i.options_tr)
    END AS options,
    i.type,
    i.reverse_scored,
    i.scoring_key,
    i.weight,
    i.notes
  FROM items i;
END;
$$ LANGUAGE plpgsql;

-- Add supported languages metadata table
CREATE TABLE IF NOT EXISTS supported_languages (
  code VARCHAR(10) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  native_name VARCHAR(100) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER
);

-- Insert supported languages
INSERT INTO supported_languages (code, name, native_name, display_order) VALUES
  ('en', 'English', 'English', 1),
  ('es', 'Spanish', 'Español', 2),
  ('fr', 'French', 'Français', 3),
  ('de', 'German', 'Deutsch', 4),
  ('it', 'Italian', 'Italiano', 5),
  ('pt', 'Portuguese', 'Português', 6),
  ('nl', 'Dutch', 'Nederlands', 7),
  ('ru', 'Russian', 'Русский', 8),
  ('zh', 'Chinese (Simplified)', '简体中文', 9),
  ('zh-tw', 'Chinese (Traditional)', '繁體中文', 10),
  ('ja', 'Japanese', '日本語', 11),
  ('ko', 'Korean', '한국어', 12),
  ('ar', 'Arabic', 'العربية', 13),
  ('tr', 'Turkish', 'Türkçe', 14),
  ('hi', 'Hindi', 'हिन्दी', 15)
ON CONFLICT (code) DO NOTHING;
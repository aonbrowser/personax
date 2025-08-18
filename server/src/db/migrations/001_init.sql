CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  locale TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS people (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  relation_type TEXT NOT NULL,
  gender TEXT,
  age INTEGER,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS assessments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('S1','S2','S3','S4')),
  version TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS items (
  id TEXT PRIMARY KEY,
  form TEXT,
  section TEXT,
  subscale TEXT,
  text_tr TEXT,
  type TEXT,
  options_tr TEXT,
  reverse_scored INTEGER DEFAULT 0,
  scoring_key TEXT,
  weight REAL DEFAULT 1.0,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS responses (
  id BIGSERIAL PRIMARY KEY,
  assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  value TEXT NOT NULL,
  rt_ms INTEGER
);

CREATE TABLE IF NOT EXISTS scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  assessment_id UUID NOT NULL REFERENCES assessments(id) ON DELETE CASCADE,
  bigfive_json JSONB,
  mbti_json JSONB,
  enneagram_json JSONB,
  attachment_json JSONB,
  conflict_json JSONB,
  social_json JSONB,
  quality_flags JSONB
);

CREATE TABLE IF NOT EXISTS dyads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  a_person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  b_person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
  relation_type TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dyad_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dyad_id UUID NOT NULL REFERENCES dyads(id) ON DELETE CASCADE,
  compatibility_score REAL,
  strengths_json JSONB,
  risks_json JSONB,
  plan_json JSONB,
  confidence REAL
);

CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  dyad_id UUID NOT NULL REFERENCES dyads(id) ON DELETE CASCADE,
  markdown TEXT,
  version TEXT
);

CREATE TABLE IF NOT EXISTS chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dyad_id UUID NOT NULL REFERENCES dyads(id) ON DELETE CASCADE,
  metadata JSONB
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  role TEXT CHECK (role IN ('user','assistant','system')),
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS language_incidents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  report_type TEXT CHECK (report_type IN ('self','other','dyad','coach')),
  user_language TEXT NOT NULL,
  detected_language TEXT NOT NULL,
  content_preview TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_people_user ON people(user_id);
CREATE INDEX IF NOT EXISTS idx_resp_assessment ON responses(assessment_id);
CREATE INDEX IF NOT EXISTS idx_resp_item ON responses(item_id);

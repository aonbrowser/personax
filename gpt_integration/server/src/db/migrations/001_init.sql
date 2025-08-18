CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TABLE IF NOT EXISTS items (
  id TEXT PRIMARY KEY,
  form TEXT,
  section TEXT,
  subscale TEXT,
  text_tr TEXT,
  type TEXT,
  options_tr TEXT,
  reverse_scored INT,
  scoring_key TEXT,
  weight REAL,
  notes TEXT
);

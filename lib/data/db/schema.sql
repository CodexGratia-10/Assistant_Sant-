-- Schéma initial SQLite pour Assistant Santé
-- Utiliser PRAGMA foreign_keys = ON au démarrage.

CREATE TABLE IF NOT EXISTS patient (
  id TEXT PRIMARY KEY, -- UUID pseudo-anonyme
  sex TEXT CHECK(sex IN ('M','F')),
  year_of_birth INTEGER, -- année pour réduire PII
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS visit (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  visit_type TEXT, -- 'consultation','followup'
  started_at INTEGER NOT NULL,
  completed_at INTEGER,
  outcome TEXT, -- 'uncomplicated','urgent_referral','other'
  referral_flag INTEGER DEFAULT 0,
  sync_status TEXT DEFAULT 'pending', -- 'pending','synced'
  FOREIGN KEY(patient_id) REFERENCES patient(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS symptom_observation (
  id TEXT PRIMARY KEY,
  visit_id TEXT NOT NULL,
  code TEXT NOT NULL, -- ex: 'fever','cough','diarrhea'
  value TEXT, -- générique (ex: 'yes','no','38.5')
  numeric_value REAL,
  captured_at INTEGER NOT NULL,
  FOREIGN KEY(visit_id) REFERENCES visit(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_symptom_visit ON symptom_observation(visit_id);
CREATE INDEX IF NOT EXISTS idx_symptom_code ON symptom_observation(code);

CREATE TABLE IF NOT EXISTS vital_sign (
  id TEXT PRIMARY KEY,
  visit_id TEXT NOT NULL,
  type TEXT NOT NULL, -- 'temperature','resp_rate','heart_rate'
  value REAL NOT NULL,
  unit TEXT NOT NULL,
  captured_at INTEGER NOT NULL,
  FOREIGN KEY(visit_id) REFERENCES visit(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS malaria_rdt (
  id TEXT PRIMARY KEY,
  visit_id TEXT NOT NULL,
  performed INTEGER NOT NULL CHECK(performed IN (0,1)),
  result TEXT CHECK(result IN ('positive','negative','invalid')),
  captured_at INTEGER NOT NULL,
  FOREIGN KEY(visit_id) REFERENCES visit(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pregnancy (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  lmp_date INTEGER, -- dernier règles (timestamp jour)
  risk_level TEXT, -- 'normal','high'
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY(patient_id) REFERENCES patient(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vaccination (
  id TEXT PRIMARY KEY,
  patient_id TEXT NOT NULL,
  vaccine_code TEXT NOT NULL, -- ex: 'BCG','DTP1'
  due_date INTEGER NOT NULL,
  administered_date INTEGER,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending','done','missed'
  FOREIGN KEY(patient_id) REFERENCES patient(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_vaccination_due ON vaccination(due_date);

CREATE TABLE IF NOT EXISTS alert (
  id TEXT PRIMARY KEY,
  patient_id TEXT,
  category TEXT NOT NULL, -- 'vaccination','pregnancy','followup'
  code TEXT NOT NULL, -- ex: 'PNC_VISIT','VACCINE_DUE'
  target_date INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'open', -- 'open','sent','ack'
  created_at INTEGER NOT NULL,
  FOREIGN KEY(patient_id) REFERENCES patient(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS idx_alert_target ON alert(target_date);

CREATE TABLE IF NOT EXISTS audit_log (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  action TEXT NOT NULL, -- 'CREATE','UPDATE','DELETE'
  timestamp INTEGER NOT NULL,
  actor TEXT, -- identifiant relais
  details TEXT
);

CREATE TABLE IF NOT EXISTS sync_event (
  id TEXT PRIMARY KEY,
  entity TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL, -- 'UPSERT','DELETE'
  created_at INTEGER NOT NULL,
  processed_at INTEGER,
  status TEXT NOT NULL DEFAULT 'queued' -- 'queued','processing','done','error'
);
CREATE INDEX IF NOT EXISTS idx_sync_status ON sync_event(status);

CREATE TABLE provider_configurations (
  id INTEGER NOT NULL PRIMARY KEY,
  product TEXT NOT NULL,
  region TEXT NOT NULL,
  model TEXT NOT NULL,
  disable_thinking INTEGER NOT NULL CHECK (disable_thinking IN (0, 1)),
  version INTEGER NOT NULL,
  credential_ref TEXT
);
CREATE TABLE credential_cleanup (reference TEXT NOT NULL PRIMARY KEY);
CREATE TABLE local_profiles (
  singleton_id INTEGER NOT NULL PRIMARY KEY,
  local_user_id TEXT NOT NULL UNIQUE,
  nickname TEXT NOT NULL,
  version INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
PRAGMA user_version = 2;

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
CREATE TABLE work_todos (
 id TEXT NOT NULL PRIMARY KEY, version INTEGER NOT NULL, category_id TEXT,
 status TEXT NOT NULL, due_at INTEGER, sort_order INTEGER NOT NULL,
 payload TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE TABLE work_categories (
 id TEXT NOT NULL PRIMARY KEY, version INTEGER NOT NULL, parent_id TEXT,
 archived INTEGER NOT NULL CHECK (archived IN (0,1)), sort_order INTEGER NOT NULL,
 payload TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE TABLE workspace_operations (
 operation_id TEXT NOT NULL PRIMARY KEY, request_digest TEXT NOT NULL, source TEXT NOT NULL,
 undo_of TEXT, receipt TEXT NOT NULL, changes TEXT NOT NULL, committed_at INTEGER NOT NULL
);
CREATE INDEX work_todos_category ON work_todos(category_id, deleted_at);
CREATE INDEX work_todos_due ON work_todos(status, due_at, deleted_at);
CREATE INDEX work_categories_parent ON work_categories(parent_id, deleted_at);
CREATE TABLE app_preference_rows (
 singleton_id INTEGER NOT NULL PRIMARY KEY, version INTEGER NOT NULL, payload TEXT NOT NULL
);
CREATE TABLE agent_run_rows (
 id TEXT NOT NULL PRIMARY KEY, session_id TEXT NOT NULL, input_id TEXT NOT NULL,
 revision INTEGER NOT NULL, status TEXT NOT NULL, initial_request TEXT NOT NULL, payload TEXT NOT NULL,
 UNIQUE(session_id, input_id)
);
CREATE TABLE agent_run_events (
 run_id TEXT NOT NULL, sequence INTEGER NOT NULL, payload TEXT NOT NULL, PRIMARY KEY(run_id, sequence)
);
CREATE TABLE chat_conversations (
 id TEXT NOT NULL PRIMARY KEY, title TEXT NOT NULL, revision INTEGER NOT NULL,
 created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE TABLE chat_turns (
 input_id TEXT NOT NULL PRIMARY KEY, session_id TEXT NOT NULL, run_id TEXT NOT NULL UNIQUE,
 content TEXT NOT NULL, position INTEGER NOT NULL, history_start INTEGER NOT NULL,
 created_at INTEGER NOT NULL, agent_enabled INTEGER NOT NULL CHECK(agent_enabled IN (0,1)),
 undone_at INTEGER, UNIQUE(session_id, position)
);
PRAGMA user_version = 6;

ALTER TABLE work_todos ADD COLUMN series_id TEXT;
ALTER TABLE work_todos ADD COLUMN occurrence_key TEXT;
ALTER TABLE work_todos ADD COLUMN occurrence_index INTEGER;
CREATE TABLE work_todo_series (
 id TEXT NOT NULL PRIMARY KEY, version INTEGER NOT NULL, payload TEXT NOT NULL,
 created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, deleted_at INTEGER
);
CREATE UNIQUE INDEX work_todos_occurrence_key ON work_todos(series_id, occurrence_key);
CREATE UNIQUE INDEX work_todos_occurrence_index ON work_todos(series_id, occurrence_index);
PRAGMA user_version = 7;

CREATE TABLE local_job_rows (
 id TEXT NOT NULL PRIMARY KEY, unique_key TEXT NOT NULL UNIQUE,
 type TEXT NOT NULL, payload TEXT NOT NULL, digest TEXT NOT NULL, status TEXT NOT NULL,
 due_at INTEGER NOT NULL, next_attempt_at INTEGER NOT NULL, attempts INTEGER NOT NULL,
 max_attempts INTEGER NOT NULL, lease_epoch INTEGER NOT NULL, lease_owner TEXT,
 lease_expires_at INTEGER, lease_started_at INTEGER, outcome TEXT, error_code TEXT
);
CREATE TABLE notification_attempts (
 id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, job_id TEXT NOT NULL,
 lease_epoch INTEGER NOT NULL, payload TEXT NOT NULL,
 cancelled INTEGER NOT NULL DEFAULT 0 CHECK(cancelled IN (0,1)),
 UNIQUE(job_id, lease_epoch)
);
PRAGMA user_version = 8;

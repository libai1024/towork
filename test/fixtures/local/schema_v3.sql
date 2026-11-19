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
PRAGMA user_version = 3;

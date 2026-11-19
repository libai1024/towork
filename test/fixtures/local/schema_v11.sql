-- v11 baseline for migration tests (drift-generated).
CREATE TABLE "provider_configurations" ("id" INTEGER NOT NULL, "product" TEXT NOT NULL, "region" TEXT NOT NULL, "model" TEXT NOT NULL, "disable_thinking" INTEGER NOT NULL CHECK (disable_thinking IN (0, 1)), "version" INTEGER NOT NULL, "credential_ref" TEXT NULL, PRIMARY KEY(id));

CREATE TABLE "credential_cleanup" ("reference" TEXT NOT NULL, PRIMARY KEY(reference));

CREATE TABLE "local_profiles" ("singleton_id" INTEGER NOT NULL, "local_user_id" TEXT NOT NULL UNIQUE, "nickname" TEXT NOT NULL, "version" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY(singleton_id));

CREATE TABLE "work_todos" ("series_id" TEXT NULL, "occurrence_key" TEXT NULL, "occurrence_index" INTEGER NULL, "id" TEXT NOT NULL, "version" INTEGER NOT NULL, "category_id" TEXT NULL, "status" TEXT NOT NULL, "due_at" INTEGER NULL, "sort_order" INTEGER NOT NULL, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "work_todo_series" ("id" TEXT NOT NULL, "version" INTEGER NOT NULL, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "work_categories" ("id" TEXT NOT NULL, "version" INTEGER NOT NULL, "parent_id" TEXT NULL, "archived" INTEGER NOT NULL CHECK (archived IN (0, 1)), "sort_order" INTEGER NOT NULL, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "workspace_operations" ("operation_id" TEXT NOT NULL, "request_digest" TEXT NOT NULL, "source" TEXT NOT NULL, "undo_of" TEXT NULL, "receipt" TEXT NOT NULL, "changes" TEXT NOT NULL, "committed_at" INTEGER NOT NULL, PRIMARY KEY(operation_id));

CREATE TABLE "work_data_tables" ("type_id" TEXT NULL, "archived" INTEGER NOT NULL CHECK (archived IN (0, 1)), "schema_revision" INTEGER NOT NULL, "id" TEXT NOT NULL, "version" INTEGER NOT NULL, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "work_data_rows" ("table_id" TEXT NOT NULL, "id" TEXT NOT NULL, "version" INTEGER NOT NULL, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "work_table_types" ("id" TEXT NOT NULL, "version" INTEGER NOT NULL, "payload" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "app_preference_rows" ("singleton_id" INTEGER NOT NULL, "version" INTEGER NOT NULL, "payload" TEXT NOT NULL, PRIMARY KEY(singleton_id));

CREATE TABLE "agent_run_rows" ("id" TEXT NOT NULL, "session_id" TEXT NOT NULL, "input_id" TEXT NOT NULL, "revision" INTEGER NOT NULL, "status" TEXT NOT NULL, "initial_request" TEXT NOT NULL, "payload" TEXT NOT NULL, PRIMARY KEY(id), UNIQUE(session_id, input_id));

CREATE TABLE "agent_run_events" ("run_id" TEXT NOT NULL, "sequence" INTEGER NOT NULL, "payload" TEXT NOT NULL, PRIMARY KEY(run_id, sequence));

CREATE TABLE "chat_conversations" ("id" TEXT NOT NULL, "title" TEXT NOT NULL, "revision" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "chat_turns" ("input_id" TEXT NOT NULL, "session_id" TEXT NOT NULL, "run_id" TEXT NOT NULL UNIQUE, "content" TEXT NOT NULL, "position" INTEGER NOT NULL, "history_start" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, "agent_enabled" INTEGER NOT NULL CHECK (agent_enabled IN (0, 1)), "undone_at" INTEGER NULL, PRIMARY KEY(input_id), UNIQUE(session_id, position));

CREATE TABLE "local_job_rows" ("id" TEXT NOT NULL, "unique_key" TEXT NOT NULL UNIQUE, "type" TEXT NOT NULL, "payload" TEXT NOT NULL, "digest" TEXT NOT NULL, "status" TEXT NOT NULL, "due_at" INTEGER NOT NULL, "next_attempt_at" INTEGER NOT NULL, "attempts" INTEGER NOT NULL, "max_attempts" INTEGER NOT NULL, "lease_epoch" INTEGER NOT NULL, "lease_owner" TEXT NULL, "lease_expires_at" INTEGER NULL, "lease_started_at" INTEGER NULL, "outcome" TEXT NULL, "error_code" TEXT NULL, PRIMARY KEY(id));

CREATE TABLE "notification_attempts" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "job_id" TEXT NOT NULL, "lease_epoch" INTEGER NOT NULL, "payload" TEXT NOT NULL, "cancelled" INTEGER NOT NULL DEFAULT 0 CHECK (cancelled IN (0, 1)), UNIQUE(job_id, lease_epoch));

CREATE TABLE "local_attachments" ("id" TEXT NOT NULL, "input_id" TEXT NOT NULL UNIQUE, "table_id" TEXT NOT NULL, "display_name" TEXT NOT NULL, "mime" TEXT NOT NULL, "original_hash" TEXT NOT NULL, "original_size" INTEGER NOT NULL, "model_hash" TEXT NOT NULL, "model_size" INTEGER NOT NULL, "width" INTEGER NOT NULL, "height" INTEGER NOT NULL, "state" TEXT NOT NULL, "created_at" INTEGER NOT NULL, PRIMARY KEY(id));

CREATE TABLE "local_memories" ("id" TEXT NOT NULL, "epoch" INTEGER NOT NULL, "kind_id" TEXT NOT NULL, "content" TEXT NOT NULL, "source" TEXT NOT NULL, "source_message_id" TEXT NULL, "source_session_id" TEXT NULL, "source_record_id" TEXT NULL, "confidence" REAL NOT NULL, "expires_at" INTEGER NULL, "version" INTEGER NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, PRIMARY KEY(id));

CREATE TABLE "local_memory_state" ("id" INTEGER NOT NULL DEFAULT 1, "epoch" INTEGER NOT NULL, "paused" INTEGER NOT NULL CHECK (paused IN (0, 1)), "updated_at" INTEGER NOT NULL, PRIMARY KEY(id));

CREATE UNIQUE INDEX work_todos_occurrence_key ON work_todos (series_id, occurrence_key);

CREATE UNIQUE INDEX work_todos_occurrence_index ON work_todos (series_id, occurrence_index);

CREATE INDEX work_todos_category ON work_todos (category_id, deleted_at);

CREATE INDEX work_todos_due ON work_todos (status, due_at, deleted_at);

CREATE INDEX work_categories_parent ON work_categories (parent_id, deleted_at);

CREATE INDEX work_data_tables_type ON work_data_tables (type_id, deleted_at);

CREATE INDEX work_data_rows_table ON work_data_rows (table_id, deleted_at);


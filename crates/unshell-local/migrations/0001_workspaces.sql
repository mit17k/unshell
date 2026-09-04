CREATE TABLE IF NOT EXISTS workspaces (
    id            TEXT PRIMARY KEY NOT NULL,
    name          TEXT NOT NULL,
    root_path     BLOB NOT NULL UNIQUE,
    staging_path  BLOB,
    state         TEXT NOT NULL CHECK (state IN ('provisioning', 'ready', 'failed')),
    failure       TEXT,
    created_at    INTEGER NOT NULL,
    updated_at    INTEGER NOT NULL
) STRICT;

CREATE INDEX IF NOT EXISTS workspaces_state_idx ON workspaces (state);

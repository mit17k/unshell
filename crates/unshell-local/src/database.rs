use std::{
    ffi::OsString,
    os::unix::ffi::{OsStrExt, OsStringExt},
    path::{Path, PathBuf},
    time::{Duration, SystemTime, UNIX_EPOCH},
};

use rusqlite::{Connection, ErrorCode, OptionalExtension, params, types::Type};
use thiserror::Error;
use unshell_core::{Workspace, WorkspaceId, WorkspaceName, WorkspaceState, WorkspaceSummary};

const MIGRATION_1: &str = include_str!("../migrations/0001_workspaces.sql");
const CURRENT_SCHEMA_VERSION: i64 = 1;

#[derive(Debug, Error)]
pub enum DatabaseError {
    #[error("database operation failed: {0}")]
    Sql(#[from] rusqlite::Error),
    #[error("workspace root already exists in the database: {}", path.display())]
    DuplicateRoot { path: PathBuf },
    #[error("workspace {id} cannot transition from {from:?} to {to:?}")]
    InvalidTransition {
        id: WorkspaceId,
        from: WorkspaceState,
        to: WorkspaceState,
    },
    #[error("workspace {0} does not exist")]
    NotFound(WorkspaceId),
    #[error("workspace {id} cannot be deleted while it is {state:?}")]
    CannotDelete {
        id: WorkspaceId,
        state: WorkspaceState,
    },
    #[error("system clock is before the Unix epoch")]
    InvalidSystemTime,
}

#[derive(Clone, Debug)]
pub(crate) struct ProvisioningRecord {
    pub workspace: Workspace,
    pub staging_path: PathBuf,
}

pub(crate) struct WorkspaceDatabase {
    connection: Connection,
}

impl WorkspaceDatabase {
    pub fn open(path: &Path) -> Result<Self, DatabaseError> {
        let connection = Connection::open(path)?;
        Self::initialize(connection)
    }

    #[cfg(test)]
    pub fn open_in_memory() -> Result<Self, DatabaseError> {
        Self::initialize(Connection::open_in_memory()?)
    }

    fn initialize(mut connection: Connection) -> Result<Self, DatabaseError> {
        connection.busy_timeout(Duration::from_secs(5))?;
        connection.pragma_update(None, "foreign_keys", true)?;
        connection.pragma_update(None, "journal_mode", "WAL")?;
        connection.pragma_update(None, "synchronous", "FULL")?;

        let version =
            connection.query_row("PRAGMA user_version", [], |row| row.get::<_, i64>(0))?;
        if version < 1 {
            let transaction = connection.transaction()?;
            transaction.execute_batch(MIGRATION_1)?;
            transaction.pragma_update(None, "user_version", 1)?;
            transaction.commit()?;
        }
        let actual = connection.query_row("PRAGMA user_version", [], |row| row.get::<_, i64>(0))?;
        if actual != CURRENT_SCHEMA_VERSION {
            return Err(DatabaseError::Sql(rusqlite::Error::InvalidQuery));
        }
        Ok(Self { connection })
    }

    pub fn insert_provisioning(
        &self,
        workspace: &Workspace,
        staging_path: &Path,
    ) -> Result<(), DatabaseError> {
        let now = unix_timestamp()?;
        let result = self.connection.execute(
            "INSERT INTO workspaces
             (id, name, root_path, staging_path, state, failure, created_at, updated_at)
             VALUES (?1, ?2, ?3, ?4, 'provisioning', NULL, ?5, ?5)",
            params![
                workspace.id.to_string(),
                workspace.name.as_str(),
                path_bytes(&workspace.root),
                path_bytes(staging_path),
                now,
            ],
        );
        match result {
            Ok(_) => Ok(()),
            Err(rusqlite::Error::SqliteFailure(error, _))
                if error.code == ErrorCode::ConstraintViolation =>
            {
                Err(DatabaseError::DuplicateRoot {
                    path: workspace.root.clone(),
                })
            }
            Err(error) => Err(DatabaseError::Sql(error)),
        }
    }

    pub fn mark_ready(&self, id: WorkspaceId) -> Result<(), DatabaseError> {
        self.transition(id, WorkspaceState::Ready, None)
    }

    pub fn mark_failed(&self, id: WorkspaceId, failure: &str) -> Result<(), DatabaseError> {
        self.transition(id, WorkspaceState::Failed, Some(failure))
    }

    pub fn delete_provisioning(&self, id: WorkspaceId) -> Result<(), DatabaseError> {
        let changed = self.connection.execute(
            "DELETE FROM workspaces WHERE id = ?1 AND state = 'provisioning'",
            [id.to_string()],
        )?;
        if changed == 1 {
            return Ok(());
        }
        let from = self.state(id)?.ok_or(DatabaseError::NotFound(id))?;
        Err(DatabaseError::CannotDelete { id, state: from })
    }

    fn transition(
        &self,
        id: WorkspaceId,
        to: WorkspaceState,
        failure: Option<&str>,
    ) -> Result<(), DatabaseError> {
        let state = match to {
            WorkspaceState::Ready => "ready",
            WorkspaceState::Failed => "failed",
            WorkspaceState::Provisioning => unreachable!("provisioning is an initial state"),
        };
        let changed = self.connection.execute(
            "UPDATE workspaces SET state = ?1, failure = ?2,
             staging_path = NULL, updated_at = ?3
             WHERE id = ?4 AND state = 'provisioning'",
            params![state, failure, unix_timestamp()?, id.to_string()],
        )?;
        if changed == 1 {
            return Ok(());
        }
        let from = self.state(id)?.ok_or(DatabaseError::NotFound(id))?;
        Err(DatabaseError::InvalidTransition { id, from, to })
    }

    fn state(&self, id: WorkspaceId) -> Result<Option<WorkspaceState>, DatabaseError> {
        let value = self
            .connection
            .query_row(
                "SELECT state FROM workspaces WHERE id = ?1",
                [id.to_string()],
                |row| row.get::<_, String>(0),
            )
            .optional()?;
        value.map(|value| decode_state(&value)).transpose()
    }

    pub fn list_ready(&self) -> Result<Vec<WorkspaceSummary>, DatabaseError> {
        let mut statement = self.connection.prepare(
            "SELECT id, name, root_path FROM workspaces
             WHERE state = 'ready' ORDER BY updated_at DESC, id DESC",
        )?;
        let rows = statement.query_map([], |row| {
            let workspace = decode_workspace_columns(row, WorkspaceState::Ready, None)?;
            Ok(WorkspaceSummary {
                id: workspace.id,
                name: workspace.name,
                root: workspace.root,
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(Into::into)
    }

    pub fn provisioning(&self) -> Result<Vec<ProvisioningRecord>, DatabaseError> {
        let mut statement = self.connection.prepare(
            "SELECT id, name, root_path, staging_path FROM workspaces
             WHERE state = 'provisioning' ORDER BY created_at",
        )?;
        let rows = statement.query_map([], |row| {
            let workspace = decode_workspace_columns(row, WorkspaceState::Provisioning, None)?;
            let staging_bytes: Vec<u8> = row.get(3)?;
            Ok(ProvisioningRecord {
                workspace,
                staging_path: path_from_bytes(staging_bytes),
            })
        })?;
        rows.collect::<Result<Vec<_>, _>>().map_err(Into::into)
    }
}

fn decode_workspace_columns(
    row: &rusqlite::Row<'_>,
    state: WorkspaceState,
    failure: Option<String>,
) -> rusqlite::Result<Workspace> {
    let id_string: String = row.get(0)?;
    let id = id_string.parse::<WorkspaceId>().map_err(|error| {
        rusqlite::Error::FromSqlConversionFailure(0, Type::Text, Box::new(error))
    })?;
    let name_string: String = row.get(1)?;
    let name = WorkspaceName::new(name_string).map_err(|error| {
        rusqlite::Error::FromSqlConversionFailure(1, Type::Text, Box::new(error))
    })?;
    let root_bytes: Vec<u8> = row.get(2)?;
    Ok(Workspace {
        id,
        name,
        root: path_from_bytes(root_bytes),
        state,
        failure,
    })
}

fn decode_state(value: &str) -> Result<WorkspaceState, DatabaseError> {
    decode_state_sql(value).map_err(DatabaseError::Sql)
}

fn decode_state_sql(value: &str) -> rusqlite::Result<WorkspaceState> {
    match value {
        "provisioning" => Ok(WorkspaceState::Provisioning),
        "ready" => Ok(WorkspaceState::Ready),
        "failed" => Ok(WorkspaceState::Failed),
        _ => Err(rusqlite::Error::InvalidQuery),
    }
}

fn path_bytes(path: &Path) -> &[u8] {
    path.as_os_str().as_bytes()
}

fn path_from_bytes(bytes: Vec<u8>) -> PathBuf {
    PathBuf::from(OsString::from_vec(bytes))
}

fn unix_timestamp() -> Result<i64, DatabaseError> {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| DatabaseError::InvalidSystemTime)?
        .as_secs();
    i64::try_from(seconds).map_err(|_| DatabaseError::InvalidSystemTime)
}

#[cfg(test)]
mod tests {
    use std::os::unix::ffi::OsStringExt;

    use super::*;

    fn workspace(root: PathBuf) -> Workspace {
        Workspace {
            id: WorkspaceId::new(),
            name: WorkspaceName::new("Example").unwrap(),
            root,
            state: WorkspaceState::Provisioning,
            failure: None,
        }
    }

    #[test]
    fn migrates_new_and_reopened_databases() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("unshell.sqlite3");
        drop(WorkspaceDatabase::open(&path).unwrap());
        let reopened = WorkspaceDatabase::open(&path).unwrap();
        assert!(reopened.list_ready().unwrap().is_empty());
    }

    #[test]
    fn rejects_duplicate_roots_and_invalid_transitions() {
        let database = WorkspaceDatabase::open_in_memory().unwrap();
        let first = workspace(PathBuf::from("/tmp/example"));
        database
            .insert_provisioning(&first, Path::new("/tmp/.stage-1"))
            .unwrap();
        let duplicate = workspace(first.root.clone());
        assert!(matches!(
            database.insert_provisioning(&duplicate, Path::new("/tmp/.stage-2")),
            Err(DatabaseError::DuplicateRoot { .. })
        ));
        database.mark_ready(first.id).unwrap();
        assert!(matches!(
            database.mark_failed(first.id, "late failure"),
            Err(DatabaseError::InvalidTransition { .. })
        ));
    }

    #[test]
    fn deleting_an_unpublished_row_allows_a_clean_retry() {
        let database = WorkspaceDatabase::open_in_memory().unwrap();
        let first = workspace(PathBuf::from("/tmp/retry"));
        database
            .insert_provisioning(&first, Path::new("/tmp/.retry-1"))
            .unwrap();
        database.delete_provisioning(first.id).unwrap();

        let retry = workspace(first.root.clone());
        database
            .insert_provisioning(&retry, Path::new("/tmp/.retry-2"))
            .unwrap();
    }

    #[test]
    fn paths_round_trip_without_utf8() {
        let database = WorkspaceDatabase::open_in_memory().unwrap();
        let root = PathBuf::from(OsString::from_vec(b"/tmp/non-utf8-\xff".to_vec()));
        let workspace = workspace(root.clone());
        database
            .insert_provisioning(&workspace, Path::new("/tmp/.stage"))
            .unwrap();
        database.mark_ready(workspace.id).unwrap();
        assert_eq!(database.list_ready().unwrap()[0].root, root);
    }
}

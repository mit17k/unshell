//! Local persistence and filesystem provisioning for Unshell.
//!
//! All operations are synchronous by design. UI callers should invoke them on
//! GPUI's background executor rather than from a render callback.

#[cfg(not(unix))]
compile_error!("unshell-local supports native macOS and Linux targets only");

mod database;
mod scaffold;

use std::{
    fs, io,
    path::{Path, PathBuf},
    sync::{Mutex, MutexGuard},
};

use database::{DatabaseError, ProvisioningRecord, WorkspaceDatabase};
use directories::ProjectDirs;
use thiserror::Error;
use unshell_core::{Workspace, WorkspaceId, WorkspaceRequest, WorkspaceState, WorkspaceSummary};

pub use database::DatabaseError as WorkspaceDatabaseError;
pub use scaffold::ScaffoldError;

const DATABASE_FILE_NAME: &str = "unshell.sqlite3";

#[derive(Debug, Error)]
pub enum LocalError {
    #[error(transparent)]
    Database(#[from] DatabaseError),
    #[error(transparent)]
    Scaffold(#[from] ScaffoldError),
    #[error("could not resolve the platform application-data directory")]
    ApplicationDataDirectoryUnavailable,
    #[error("could not create application-data directory {path}: {source}")]
    CreateApplicationDataDirectory {
        path: PathBuf,
        #[source]
        source: io::Error,
    },
    #[error("local workspace service lock was poisoned")]
    LockPoisoned,
}

/// Results of conservatively reconciling interrupted provisioning operations.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct ReconciliationReport {
    pub recovered: usize,
    pub failed: usize,
}

/// Thread-safe owner of Unshell's local database and workspace provisioner.
///
/// `rusqlite::Connection` is not `Sync`; the mutex provides serialization and
/// allows this service to be placed behind an `Arc` for background tasks.
pub struct LocalWorkspaceService {
    database: Mutex<WorkspaceDatabase>,
}

impl LocalWorkspaceService {
    /// Open the private database in the platform-standard application-data directory.
    /// Migrations and interrupted-operation recovery run before this returns.
    pub fn open_default() -> Result<Self, LocalError> {
        let path = default_database_path()?;
        let directory = path
            .parent()
            .ok_or(LocalError::ApplicationDataDirectoryUnavailable)?;
        fs::create_dir_all(directory).map_err(|source| {
            LocalError::CreateApplicationDataDirectory {
                path: directory.to_path_buf(),
                source,
            }
        })?;
        Self::open(path)
    }

    /// Open an explicit database path. Intended for embedding and tests.
    pub fn open(path: impl AsRef<Path>) -> Result<Self, LocalError> {
        let database = WorkspaceDatabase::open(path.as_ref())?;
        let service = Self {
            database: Mutex::new(database),
        };
        service.reconcile()?;
        Ok(service)
    }

    /// List successfully published workspaces, most recently updated first.
    pub fn list_ready(&self) -> Result<Vec<WorkspaceSummary>, LocalError> {
        Ok(self.database()?.list_ready()?)
    }

    /// Build, verify, atomically publish, and record a new workspace.
    pub fn create_workspace(
        &self,
        request: WorkspaceRequest,
    ) -> Result<WorkspaceSummary, LocalError> {
        let parent = canonical_parent(&request.parent)?;
        let root = parent.join(request.name.as_str());
        ensure_destination_absent(&root)?;

        let id = WorkspaceId::new();
        let staging = scaffold::staging_path(&parent, id);
        let workspace = Workspace {
            id,
            name: request.name,
            root: root.clone(),
            state: WorkspaceState::Provisioning,
            failure: None,
        };

        let database = self.database()?;
        database.insert_provisioning(&workspace, &staging)?;

        let provision_result = (|| {
            scaffold::build(&staging)?;
            scaffold::verify(&staging)?;
            scaffold::publish(&staging, &root)?;
            // Re-check the visible path immediately before recording it ready.
            scaffold::verify(&root)?;
            Ok::<_, ScaffoldError>(())
        })();

        if let Err(error) = provision_result {
            // Cleanup is deliberately restricted to this operation's exact hidden path.
            if scaffold::cleanup_staging(&staging, &parent, id).is_ok() {
                // Nothing was published and all app-owned filesystem state is gone,
                // so remove the provisional row and allow the user to retry.
                let _ = database.delete_provisioning(id);
            } else {
                // Retain a diagnostic row when cleanup needs startup recovery.
                let _ = database.mark_failed(id, &error.to_string());
            }
            return Err(LocalError::Scaffold(error));
        }

        // If this update fails, leave the row provisioning: startup reconciliation
        // will verify the now-visible tree and complete the transition.
        database.mark_ready(id)?;
        Ok(WorkspaceSummary {
            id,
            name: workspace.name,
            root,
        })
    }

    /// Resolve rows left provisioning by a crash or database failure.
    pub fn reconcile(&self) -> Result<ReconciliationReport, LocalError> {
        let database = self.database()?;
        let records = database.provisioning()?;
        let mut report = ReconciliationReport::default();
        for record in records {
            match reconcile_one(&database, &record) {
                Ok(true) => report.recovered += 1,
                Ok(false) => report.failed += 1,
                Err(error) => {
                    // Database failures must remain visible to the caller so a row is
                    // never silently reported as reconciled.
                    return Err(error);
                }
            }
        }
        Ok(report)
    }

    fn database(&self) -> Result<MutexGuard<'_, WorkspaceDatabase>, LocalError> {
        self.database.lock().map_err(|_| LocalError::LockPoisoned)
    }
}

/// Resolve Unshell's private SQLite path without creating it.
pub fn default_database_path() -> Result<PathBuf, LocalError> {
    let project = ProjectDirs::from("dev", "unshell", "Unshell")
        .ok_or(LocalError::ApplicationDataDirectoryUnavailable)?;
    Ok(project.data_local_dir().join(DATABASE_FILE_NAME))
}

fn canonical_parent(parent: &Path) -> Result<PathBuf, ScaffoldError> {
    if !parent.is_dir() {
        return Err(ScaffoldError::InvalidParent {
            path: parent.to_path_buf(),
        });
    }
    fs::canonicalize(parent).map_err(|source| ScaffoldError::Io {
        path: parent.to_path_buf(),
        source,
    })
}

fn ensure_destination_absent(root: &Path) -> Result<(), ScaffoldError> {
    match fs::symlink_metadata(root) {
        Ok(_) => Err(ScaffoldError::DestinationExists {
            path: root.to_path_buf(),
        }),
        Err(error) if error.kind() == io::ErrorKind::NotFound => Ok(()),
        Err(source) => Err(ScaffoldError::Io {
            path: root.to_path_buf(),
            source,
        }),
    }
}

/// `Ok(true)` means recovered to ready; `Ok(false)` means safely marked failed.
fn reconcile_one(
    database: &WorkspaceDatabase,
    record: &ProvisioningRecord,
) -> Result<bool, LocalError> {
    let root = &record.workspace.root;
    let id = record.workspace.id;
    let Some(parent) = root.parent() else {
        database.mark_failed(id, "recorded workspace root has no parent")?;
        return Ok(false);
    };
    let expected_staging = scaffold::staging_path(parent, id);
    if record.staging_path != expected_staging {
        database.mark_failed(id, "recorded staging path is not app-owned")?;
        return Ok(false);
    }

    if path_exists(root)? {
        let result = scaffold::verify(root);
        // Once a destination exists, never alter it during recovery.
        let _ = scaffold::cleanup_staging(&record.staging_path, parent, id);
        return match result {
            Ok(()) => {
                database.mark_ready(id)?;
                Ok(true)
            }
            Err(error) => {
                database.mark_failed(id, &format!("published workspace is invalid: {error}"))?;
                Ok(false)
            }
        };
    }

    if !path_exists(&record.staging_path)? {
        database.mark_failed(id, "workspace and staging directory are both missing")?;
        return Ok(false);
    }

    if let Err(error) = scaffold::verify(&record.staging_path) {
        scaffold::cleanup_staging(&record.staging_path, parent, id)?;
        database.mark_failed(id, &format!("staged workspace is invalid: {error}"))?;
        return Ok(false);
    }

    match scaffold::publish(&record.staging_path, root) {
        Ok(()) => {
            database.mark_ready(id)?;
            Ok(true)
        }
        Err(error) => {
            scaffold::cleanup_staging(&record.staging_path, parent, id)?;
            database.mark_failed(id, &format!("could not publish staged workspace: {error}"))?;
            Ok(false)
        }
    }
}

fn path_exists(path: &Path) -> Result<bool, ScaffoldError> {
    match fs::symlink_metadata(path) {
        Ok(_) => Ok(true),
        Err(error) if error.kind() == io::ErrorKind::NotFound => Ok(false),
        Err(source) => Err(ScaffoldError::Io {
            path: path.to_path_buf(),
            source,
        }),
    }
}

#[cfg(test)]
mod tests {
    use std::{fs, sync::Arc};

    use super::*;
    use unshell_core::WorkspaceName;

    fn assert_send_sync<T: Send + Sync>() {}

    fn request(parent: &Path, name: &str) -> WorkspaceRequest {
        WorkspaceRequest {
            parent: parent.to_path_buf(),
            name: WorkspaceName::new(name).unwrap(),
        }
    }

    #[test]
    fn service_is_send_and_sync_for_background_tasks() {
        assert_send_sync::<LocalWorkspaceService>();
        assert_send_sync::<Arc<LocalWorkspaceService>>();
    }

    #[test]
    fn creates_and_lists_a_complete_workspace() {
        let temp = tempfile::tempdir().unwrap();
        let service = LocalWorkspaceService::open(temp.path().join("db.sqlite3")).unwrap();
        let summary = service
            .create_workspace(request(temp.path(), "My Workspace"))
            .unwrap();
        assert_eq!(summary.name.as_str(), "My Workspace");
        scaffold::verify(&summary.root).unwrap();
        assert_eq!(service.list_ready().unwrap(), vec![summary]);
    }

    #[test]
    fn collision_preserves_user_directory_and_records_no_ready_workspace() {
        let temp = tempfile::tempdir().unwrap();
        let destination = temp.path().join("Existing");
        fs::create_dir(&destination).unwrap();
        fs::write(destination.join("keep"), b"mine").unwrap();
        let service = LocalWorkspaceService::open(temp.path().join("db.sqlite3")).unwrap();
        assert!(matches!(
            service.create_workspace(request(temp.path(), "Existing")),
            Err(LocalError::Scaffold(
                ScaffoldError::DestinationExists { .. }
            ))
        ));
        assert_eq!(fs::read(destination.join("keep")).unwrap(), b"mine");
        assert!(service.list_ready().unwrap().is_empty());
    }

    #[test]
    fn reconciliation_publishes_a_complete_interrupted_stage() {
        let temp = tempfile::tempdir().unwrap();
        let database_path = temp.path().join("db.sqlite3");
        let database = WorkspaceDatabase::open(&database_path).unwrap();
        let id = WorkspaceId::new();
        let root = temp.path().join("Recovered");
        let stage = scaffold::staging_path(temp.path(), id);
        let workspace = Workspace {
            id,
            name: WorkspaceName::new("Recovered").unwrap(),
            root: root.clone(),
            state: WorkspaceState::Provisioning,
            failure: None,
        };
        database.insert_provisioning(&workspace, &stage).unwrap();
        scaffold::build(&stage).unwrap();
        drop(database);

        let service = LocalWorkspaceService::open(&database_path).unwrap();
        assert!(root.is_dir());
        assert!(!stage.exists());
        assert_eq!(service.list_ready().unwrap()[0].root, root);
    }

    #[test]
    fn reconciliation_never_deletes_an_incomplete_visible_destination() {
        let temp = tempfile::tempdir().unwrap();
        let database_path = temp.path().join("db.sqlite3");
        let database = WorkspaceDatabase::open(&database_path).unwrap();
        let id = WorkspaceId::new();
        let root = temp.path().join("Collision");
        let stage = scaffold::staging_path(temp.path(), id);
        let workspace = Workspace {
            id,
            name: WorkspaceName::new("Collision").unwrap(),
            root: root.clone(),
            state: WorkspaceState::Provisioning,
            failure: None,
        };
        database.insert_provisioning(&workspace, &stage).unwrap();
        scaffold::build(&stage).unwrap();
        fs::create_dir(&root).unwrap();
        fs::write(root.join("user-file"), b"keep").unwrap();
        drop(database);

        let service = LocalWorkspaceService::open(&database_path).unwrap();
        assert_eq!(fs::read(root.join("user-file")).unwrap(), b"keep");
        assert!(!stage.exists());
        assert!(service.list_ready().unwrap().is_empty());
    }
}

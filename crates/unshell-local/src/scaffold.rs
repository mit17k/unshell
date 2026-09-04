use std::{
    collections::BTreeSet,
    ffi::OsString,
    fs, io,
    os::unix::fs::symlink,
    path::{Path, PathBuf},
};

use rustix::fs::{CWD, RenameFlags, renameat_with};
use thiserror::Error;
use unshell_core::WorkspaceId;

const ROOT_DIRECTORIES: [&str; 4] = ["knowledge", "nix", "repos", "trees"];
const ROOT_FILES: [(&str, &[u8]); 4] = [
    (".envrc", include_bytes!("../templates/.envrc")),
    (
        "CONTRIBUTION.md",
        include_bytes!("../templates/CONTRIBUTION.md"),
    ),
    ("flake.nix", include_bytes!("../templates/flake.nix")),
    ("justfile", include_bytes!("../templates/justfile")),
];
const NIX_FILES: [(&str, &[u8]); 2] = [
    ("env.nix", include_bytes!("../templates/env.nix")),
    ("tools.nix", include_bytes!("../templates/tools.nix")),
];
const CONTRIBUTION_TARGET: &str = "CONTRIBUTION.md";

#[derive(Debug, Error)]
pub enum ScaffoldError {
    #[error("workspace parent is not an existing directory: {}", path.display())]
    InvalidParent { path: PathBuf },
    #[error("workspace destination already exists: {}", path.display())]
    DestinationExists { path: PathBuf },
    #[error("workspace staging path already exists: {}", path.display())]
    StagingExists { path: PathBuf },
    #[error("workspace layout is incomplete or modified at {path}: {reason}")]
    InvalidLayout { path: PathBuf, reason: String },
    #[error("filesystem operation failed for {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: io::Error,
    },
}

#[must_use]
pub(crate) fn staging_path(parent: &Path, id: WorkspaceId) -> PathBuf {
    parent.join(format!(".unshell-{id}.staging"))
}

pub(crate) fn build(path: &Path) -> Result<(), ScaffoldError> {
    match fs::create_dir(path) {
        Ok(()) => {}
        Err(error) if error.kind() == io::ErrorKind::AlreadyExists => {
            return Err(ScaffoldError::StagingExists {
                path: path.to_path_buf(),
            });
        }
        Err(source) => return Err(io_error(path, source)),
    }

    for directory in ROOT_DIRECTORIES {
        create_dir(&path.join(directory))?;
    }
    for (name, contents) in ROOT_FILES {
        write_new(&path.join(name), contents)?;
    }
    for (name, contents) in NIX_FILES {
        write_new(&path.join("nix").join(name), contents)?;
    }
    create_symlink(&path.join("CLAUDE.md"))?;
    create_symlink(&path.join("AGENTS.md"))?;
    Ok(())
}

pub(crate) fn verify(root: &Path) -> Result<(), ScaffoldError> {
    let expected_root: BTreeSet<OsString> = [
        "repos",
        "trees",
        "knowledge",
        "nix",
        "flake.nix",
        "justfile",
        ".envrc",
        "CONTRIBUTION.md",
        "CLAUDE.md",
        "AGENTS.md",
    ]
    .into_iter()
    .map(OsString::from)
    .collect();
    verify_entries(root, &expected_root)?;

    for directory in ["repos", "trees", "knowledge"] {
        verify_directory(&root.join(directory))?;
        verify_entries(&root.join(directory), &BTreeSet::new())?;
    }
    verify_directory(&root.join("nix"))?;
    let nix_entries = ["env.nix", "tools.nix"]
        .into_iter()
        .map(OsString::from)
        .collect();
    verify_entries(&root.join("nix"), &nix_entries)?;

    for (name, expected) in ROOT_FILES {
        verify_file(&root.join(name), expected)?;
    }
    for (name, expected) in NIX_FILES {
        verify_file(&root.join("nix").join(name), expected)?;
    }
    verify_symlink(&root.join("CLAUDE.md"))?;
    verify_symlink(&root.join("AGENTS.md"))?;
    Ok(())
}

pub(crate) fn publish(staging: &Path, destination: &Path) -> Result<(), ScaffoldError> {
    renameat_with(CWD, staging, CWD, destination, RenameFlags::NOREPLACE).map_err(|error| {
        let source = io::Error::from_raw_os_error(error.raw_os_error());
        if source.kind() == io::ErrorKind::AlreadyExists {
            ScaffoldError::DestinationExists {
                path: destination.to_path_buf(),
            }
        } else {
            io_error(destination, source)
        }
    })
}

/// Remove only the exact app-owned staging directory for this operation.
pub(crate) fn cleanup_staging(
    staging: &Path,
    parent: &Path,
    id: WorkspaceId,
) -> Result<(), ScaffoldError> {
    if staging != staging_path(parent, id) || staging.parent() != Some(parent) {
        return Ok(());
    }
    let metadata = match fs::symlink_metadata(staging) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(()),
        Err(source) => return Err(io_error(staging, source)),
    };
    if !metadata.file_type().is_dir() || metadata.file_type().is_symlink() {
        return Ok(());
    }
    fs::remove_dir_all(staging).map_err(|source| io_error(staging, source))
}

fn create_dir(path: &Path) -> Result<(), ScaffoldError> {
    fs::create_dir(path).map_err(|source| io_error(path, source))
}

fn write_new(path: &Path, contents: &[u8]) -> Result<(), ScaffoldError> {
    use std::io::Write;
    let mut file = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(path)
        .map_err(|source| io_error(path, source))?;
    file.write_all(contents)
        .map_err(|source| io_error(path, source))?;
    file.sync_all().map_err(|source| io_error(path, source))
}

fn create_symlink(path: &Path) -> Result<(), ScaffoldError> {
    symlink(CONTRIBUTION_TARGET, path).map_err(|source| io_error(path, source))
}

fn verify_entries(path: &Path, expected: &BTreeSet<OsString>) -> Result<(), ScaffoldError> {
    let entries = fs::read_dir(path)
        .map_err(|source| io_error(path, source))?
        .map(|entry| entry.map(|entry| entry.file_name()))
        .collect::<Result<BTreeSet<_>, _>>()
        .map_err(|source| io_error(path, source))?;
    if &entries != expected {
        return Err(invalid_layout(
            path,
            format!("expected entries {expected:?}, found {entries:?}"),
        ));
    }
    Ok(())
}

fn verify_directory(path: &Path) -> Result<(), ScaffoldError> {
    let metadata = fs::symlink_metadata(path).map_err(|source| io_error(path, source))?;
    if !metadata.file_type().is_dir() || metadata.file_type().is_symlink() {
        return Err(invalid_layout(path, "expected a directory"));
    }
    Ok(())
}

fn verify_file(path: &Path, expected: &[u8]) -> Result<(), ScaffoldError> {
    let metadata = fs::symlink_metadata(path).map_err(|source| io_error(path, source))?;
    if !metadata.file_type().is_file() || metadata.file_type().is_symlink() {
        return Err(invalid_layout(path, "expected a regular file"));
    }
    let actual = fs::read(path).map_err(|source| io_error(path, source))?;
    if actual != expected {
        return Err(invalid_layout(path, "file content does not match template"));
    }
    Ok(())
}

fn verify_symlink(path: &Path) -> Result<(), ScaffoldError> {
    let metadata = fs::symlink_metadata(path).map_err(|source| io_error(path, source))?;
    if !metadata.file_type().is_symlink() {
        return Err(invalid_layout(path, "expected a symbolic link"));
    }
    let target = fs::read_link(path).map_err(|source| io_error(path, source))?;
    if target != Path::new(CONTRIBUTION_TARGET) {
        return Err(invalid_layout(
            path,
            format!("expected relative target {CONTRIBUTION_TARGET:?}, found {target:?}"),
        ));
    }
    Ok(())
}

fn invalid_layout(path: &Path, reason: impl Into<String>) -> ScaffoldError {
    ScaffoldError::InvalidLayout {
        path: path.to_path_buf(),
        reason: reason.into(),
    }
}

fn io_error(path: &Path, source: io::Error) -> ScaffoldError {
    ScaffoldError::Io {
        path: path.to_path_buf(),
        source,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn builds_and_verifies_exact_layout() {
        let temp = tempfile::tempdir().unwrap();
        let stage = temp.path().join("stage");
        build(&stage).unwrap();
        verify(&stage).unwrap();
    }

    #[test]
    fn relative_links_survive_a_move() {
        let temp = tempfile::tempdir().unwrap();
        let stage = temp.path().join("stage");
        let moved = temp.path().join("moved");
        build(&stage).unwrap();
        fs::rename(&stage, &moved).unwrap();
        assert_eq!(
            fs::read_to_string(moved.join("AGENTS.md")).unwrap(),
            include_str!("../templates/CONTRIBUTION.md")
        );
        verify(&moved).unwrap();
    }

    #[test]
    fn publish_never_replaces_a_destination() {
        let temp = tempfile::tempdir().unwrap();
        let stage = temp.path().join("stage");
        let destination = temp.path().join("destination");
        build(&stage).unwrap();
        fs::create_dir(&destination).unwrap();
        fs::write(destination.join("owned-by-user"), b"keep").unwrap();
        assert!(matches!(
            publish(&stage, &destination),
            Err(ScaffoldError::DestinationExists { .. })
        ));
        assert_eq!(
            fs::read(destination.join("owned-by-user")).unwrap(),
            b"keep"
        );
        assert!(stage.exists());
    }

    #[test]
    fn verification_detects_extra_entries_and_modified_templates() {
        let temp = tempfile::tempdir().unwrap();
        let stage = temp.path().join("stage");
        build(&stage).unwrap();
        fs::write(stage.join("extra"), b"unexpected").unwrap();
        assert!(matches!(
            verify(&stage),
            Err(ScaffoldError::InvalidLayout { .. })
        ));
        fs::remove_file(stage.join("extra")).unwrap();
        fs::write(stage.join("flake.nix"), b"changed").unwrap();
        assert!(matches!(
            verify(&stage),
            Err(ScaffoldError::InvalidLayout { .. })
        ));
    }
}

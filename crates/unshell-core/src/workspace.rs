use std::{fmt, path::PathBuf, str::FromStr};

use thiserror::Error;
use uuid::Uuid;

/// A stable identity for a workspace, independent of its filesystem location.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct WorkspaceId(Uuid);

impl WorkspaceId {
    #[must_use]
    pub fn new() -> Self {
        Self(Uuid::now_v7())
    }

    #[must_use]
    pub const fn from_uuid(value: Uuid) -> Self {
        Self(value)
    }

    #[must_use]
    pub const fn as_uuid(self) -> Uuid {
        self.0
    }
}

impl Default for WorkspaceId {
    fn default() -> Self {
        Self::new()
    }
}

impl fmt::Display for WorkspaceId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(formatter)
    }
}

impl FromStr for WorkspaceId {
    type Err = uuid::Error;

    fn from_str(value: &str) -> Result<Self, Self::Err> {
        Uuid::parse_str(value).map(Self)
    }
}

/// A user-visible directory name that is safe to append as one path component.
#[derive(Clone, Debug, Eq, Hash, PartialEq)]
pub struct WorkspaceName(String);

impl WorkspaceName {
    pub const MAX_BYTES: usize = 128;

    pub fn new(value: impl Into<String>) -> Result<Self, InvalidWorkspaceName> {
        let value = value.into();
        validate_name(&value)?;
        Ok(Self(value))
    }

    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for WorkspaceName {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        self.0.fmt(formatter)
    }
}

impl AsRef<str> for WorkspaceName {
    fn as_ref(&self) -> &str {
        self.as_str()
    }
}

impl TryFrom<String> for WorkspaceName {
    type Error = InvalidWorkspaceName;

    fn try_from(value: String) -> Result<Self, Self::Error> {
        Self::new(value)
    }
}

impl TryFrom<&str> for WorkspaceName {
    type Error = InvalidWorkspaceName;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Self::new(value)
    }
}

#[derive(Clone, Debug, Error, Eq, PartialEq)]
pub enum InvalidWorkspaceName {
    #[error("workspace name cannot be empty")]
    Empty,
    #[error("workspace name cannot begin with a dot")]
    Hidden,
    #[error("workspace name cannot begin or end with whitespace")]
    SurroundingWhitespace,
    #[error("workspace name cannot contain path separators")]
    PathSeparator,
    #[error("workspace name cannot contain control characters")]
    ControlCharacter,
    #[error("workspace name cannot exceed {max_bytes} bytes (got {actual_bytes})")]
    TooLong {
        max_bytes: usize,
        actual_bytes: usize,
    },
}

fn validate_name(value: &str) -> Result<(), InvalidWorkspaceName> {
    if value.is_empty() {
        return Err(InvalidWorkspaceName::Empty);
    }
    if value.starts_with('.') {
        return Err(InvalidWorkspaceName::Hidden);
    }
    if value.trim() != value {
        return Err(InvalidWorkspaceName::SurroundingWhitespace);
    }
    if value.contains(['/', '\\']) {
        return Err(InvalidWorkspaceName::PathSeparator);
    }
    if value.chars().any(char::is_control) {
        return Err(InvalidWorkspaceName::ControlCharacter);
    }
    if value.len() > WorkspaceName::MAX_BYTES {
        return Err(InvalidWorkspaceName::TooLong {
            max_bytes: WorkspaceName::MAX_BYTES,
            actual_bytes: value.len(),
        });
    }
    Ok(())
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum WorkspaceState {
    Provisioning,
    Ready,
    Failed,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorkspaceRequest {
    pub parent: PathBuf,
    pub name: WorkspaceName,
}

impl WorkspaceRequest {
    #[must_use]
    pub fn root(&self) -> PathBuf {
        self.parent.join(self.name.as_str())
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Workspace {
    pub id: WorkspaceId,
    pub name: WorkspaceName,
    pub root: PathBuf,
    pub state: WorkspaceState,
    pub failure: Option<String>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorkspaceSummary {
    pub id: WorkspaceId,
    pub name: WorkspaceName,
    pub root: PathBuf,
}

impl TryFrom<Workspace> for WorkspaceSummary {
    type Error = WorkspaceState;

    fn try_from(workspace: Workspace) -> Result<Self, Self::Error> {
        if workspace.state != WorkspaceState::Ready {
            return Err(workspace.state);
        }
        Ok(Self {
            id: workspace.id,
            name: workspace.name,
            root: workspace.root,
        })
    }
}

impl WorkspaceSummary {
    #[must_use]
    pub const fn id(&self) -> WorkspaceId {
        self.id
    }

    #[must_use]
    pub fn name(&self) -> &WorkspaceName {
        &self.name
    }

    #[must_use]
    pub fn root(&self) -> &std::path::Path {
        &self.root
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_spaces_and_unicode_without_rewriting() {
        let name = WorkspaceName::new("Café tools").unwrap();
        assert_eq!(name.as_str(), "Café tools");
    }

    #[test]
    fn rejects_unsafe_or_ambiguous_names() {
        assert_eq!(WorkspaceName::new(""), Err(InvalidWorkspaceName::Empty));
        assert_eq!(
            WorkspaceName::new(".hidden"),
            Err(InvalidWorkspaceName::Hidden)
        );
        assert_eq!(
            WorkspaceName::new(" trailing "),
            Err(InvalidWorkspaceName::SurroundingWhitespace)
        );
        assert_eq!(
            WorkspaceName::new("one/two"),
            Err(InvalidWorkspaceName::PathSeparator)
        );
        assert_eq!(
            WorkspaceName::new("one\\two"),
            Err(InvalidWorkspaceName::PathSeparator)
        );
        assert_eq!(
            WorkspaceName::new("line\nbreak"),
            Err(InvalidWorkspaceName::ControlCharacter)
        );
    }

    #[test]
    fn byte_limit_handles_multibyte_names() {
        assert!(WorkspaceName::new("é".repeat(64)).is_ok());
        assert!(matches!(
            WorkspaceName::new(format!("{}a", "é".repeat(64))),
            Err(InvalidWorkspaceName::TooLong { .. })
        ));
    }
}

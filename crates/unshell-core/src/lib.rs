//! GPUI-free domain types shared by Unshell features and adapters.

mod workspace;

pub use workspace::{
    InvalidWorkspaceName, Workspace, WorkspaceId, WorkspaceName, WorkspaceRequest, WorkspaceState,
    WorkspaceSummary,
};

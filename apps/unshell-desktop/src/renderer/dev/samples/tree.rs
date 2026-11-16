use std::collections::HashMap;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, PartialEq)]
pub enum Change {
    Added,
    Modified { lines: u32 },
    Deleted,
}

pub struct Worktree<'a> {
    root: &'a Path,
    changes: HashMap<PathBuf, Change>,
}

impl<'a> Worktree<'a> {
    pub fn new(root: &'a Path) -> Self {
        Self { root, changes: HashMap::new() }
    }

    pub fn record(&mut self, path: impl Into<PathBuf>, change: Change) -> Option<Change> {
        self.changes.insert(path.into(), change)
    }

    /// Total modified lines, ignoring additions and deletions.
    pub fn churn(&self) -> u32 {
        self.changes
            .values()
            .filter_map(|c| match c {
                Change::Modified { lines } => Some(*lines),
                _ => None,
            })
            .sum()
    }
}

fn main() {
    let mut tree = Worktree::new(Path::new("."));
    tree.record("src/main.rs", Change::Modified { lines: 12 });
    println!("{} lines changed under {:?}", tree.churn(), tree.root);
}

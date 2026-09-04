use gpui::{Context, IntoElement, div, prelude::*, px, rgb};
use unshell_core::WorkspaceSummary;
use unshell_ui::Theme;

use crate::RootView;

pub(crate) fn workspace_list(
    workspaces: &[WorkspaceSummary],
    theme: Theme,
    cx: &mut Context<RootView>,
) -> impl IntoElement {
    let mut rows = div().flex().flex_col().gap_3();
    for (index, workspace) in workspaces.iter().enumerate() {
        rows = rows.child(workspace_row(index, workspace, theme, cx));
    }

    div()
        .id("workspace-list")
        .flex_1()
        .w_full()
        .overflow_scroll()
        .bg(rgb(theme.canvas))
        .child(
            div()
                .w_full()
                .max_w(px(1_120.0))
                .mx_auto()
                .px_8()
                .py_10()
                .flex()
                .flex_col()
                .gap_8()
                .child(
                    div()
                        .flex()
                        .items_end()
                        .justify_between()
                        .gap_8()
                        .child(
                            div()
                                .min_w_0()
                                .flex_1()
                                .flex()
                                .flex_col()
                                .gap_2()
                                .child(
                                    div()
                                        .font_family("Menlo")
                                        .text_xs()
                                        .text_color(rgb(theme.accent))
                                        .child("01 // WORKSPACES"),
                                )
                                .child(
                                    div()
                                        .font_family("Georgia")
                                        .text_3xl()
                                        .child("Your workspaces"),
                                )
                                .child(
                                    div()
                                        .max_w(px(660.0))
                                        .text_sm()
                                        .line_height(px(21.0))
                                        .text_color(rgb(theme.text_muted))
                                        .child("Local developer environments managed by Unshell. Each workspace keeps repositories, worktrees, knowledge, and tooling under one deliberate structure."),
                                ),
                        )
                        .child(
                            div()
                                .id("create-workspace")
                                .flex_none()
                                .px_4()
                                .py_2()
                                .rounded(px(2.0))
                                .bg(rgb(theme.accent))
                                .text_color(rgb(theme.accent_text))
                                .text_sm()
                                .font_weight(gpui::FontWeight::SEMIBOLD)
                                .cursor_pointer()
                                .hover(move |style| style.opacity(0.88))
                                .child("+  New workspace")
                                .on_click(cx.listener(RootView::create_new_workspace)),
                        ),
                )
                .child(
                    div()
                        .flex()
                        .flex_col()
                        .gap_3()
                        .pt_5()
                        .border_t_1()
                        .border_color(rgb(theme.border))
                        .child(
                            div()
                                .flex()
                                .items_center()
                                .justify_between()
                                .font_family("Menlo")
                                .text_xs()
                                .text_color(rgb(theme.text_muted))
                                .child("READY WORKSPACES")
                                .child(format!("{:02} TOTAL", workspaces.len())),
                        )
                        .child(rows),
                ),
        )
}

fn workspace_row(
    index: usize,
    workspace: &WorkspaceSummary,
    theme: Theme,
    cx: &mut Context<RootView>,
) -> impl IntoElement + use<> {
    let id = workspace.id;
    let name = workspace.name.as_str().to_owned();
    let path = workspace.root.display().to_string();

    div()
        .id(("workspace-row", index))
        .w_full()
        .min_h(px(88.0))
        .px_4()
        .py_3()
        .flex()
        .items_center()
        .gap_4()
        .border_1()
        .border_color(rgb(theme.border))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .cursor_pointer()
        .hover(move |style| {
            style
                .bg(rgb(theme.surface_raised))
                .border_color(rgb(theme.accent))
        })
        .child(
            div()
                .w(px(36.0))
                .flex_none()
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.accent))
                .child(format!("{:02}", index + 1)),
        )
        .child(div().w(px(1.0)).h(px(44.0)).bg(rgb(theme.border)))
        .child(
            div()
                .min_w_0()
                .flex_1()
                .flex()
                .flex_col()
                .gap_2()
                .child(
                    div()
                        .text_lg()
                        .font_weight(gpui::FontWeight::SEMIBOLD)
                        .child(name),
                )
                .child(
                    div()
                        .w_full()
                        .overflow_hidden()
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(theme.text_muted))
                        .child(path),
                ),
        )
        .child(
            div()
                .flex_none()
                .flex()
                .items_center()
                .gap_2()
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.success))
                .child(div().size(px(6.0)).rounded_full().bg(rgb(theme.success)))
                .child("OPEN  →"),
        )
        .on_click(cx.listener(move |this, _, _, cx| this.select_workspace(id, cx)))
}

pub(crate) fn record_created(workspaces: &mut Vec<WorkspaceSummary>, created: WorkspaceSummary) {
    workspaces.retain(|workspace| workspace.id != created.id);
    workspaces.insert(0, created);
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use unshell_core::{WorkspaceId, WorkspaceName, WorkspaceSummary};

    use super::record_created;

    fn summary(name: &str) -> WorkspaceSummary {
        WorkspaceSummary {
            id: WorkspaceId::new(),
            name: WorkspaceName::new(name).unwrap(),
            root: PathBuf::from("/tmp").join(name),
        }
    }

    #[test]
    fn newly_created_workspace_is_first_without_duplicates() {
        let first = summary("first");
        let second = summary("second");
        let mut workspaces = vec![first.clone(), second.clone()];

        record_created(&mut workspaces, second.clone());

        assert_eq!(workspaces, vec![second, first]);
    }
}

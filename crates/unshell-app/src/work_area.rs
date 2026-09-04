use gpui::{Context, IntoElement, div, prelude::*, px, rgb};
use unshell_core::{WorkspaceId, WorkspaceSummary};
use unshell_ui::Theme;

use crate::RootView;

pub(crate) fn work_area(
    selected: &WorkspaceSummary,
    workspaces: &[WorkspaceSummary],
    workspace_menu_open: bool,
    theme: Theme,
    cx: &mut Context<RootView>,
) -> impl IntoElement + use<> {
    div()
        .id("work-area")
        .flex_1()
        .min_h_0()
        .w_full()
        .flex()
        .bg(rgb(theme.canvas))
        .child(sidebar(
            selected,
            workspaces,
            workspace_menu_open,
            theme,
            cx,
        ))
        .child(main_panel(selected, theme))
}

fn sidebar(
    selected: &WorkspaceSummary,
    workspaces: &[WorkspaceSummary],
    workspace_menu_open: bool,
    theme: Theme,
    cx: &mut Context<RootView>,
) -> impl IntoElement + use<> {
    div()
        .id("workspace-sidebar")
        .relative()
        .w(px(264.0))
        .h_full()
        .flex_none()
        .flex()
        .flex_col()
        .border_r_1()
        .border_color(rgb(theme.border))
        .bg(rgb(theme.surface))
        .child(workspace_switcher(selected, theme, cx))
        .child(
            div()
                .id("workspace-navigation-scroll")
                .flex_1()
                .min_h_0()
                .overflow_scroll()
                .px_3()
                .py_4()
                .flex()
                .flex_col()
                .gap_5()
                .child(navigation_group(
                    "WORKSPACE",
                    &[
                        ("◇", "Overview", true),
                        ("⌘", "Repositories", false),
                        ("⑂", "Worktrees", false),
                        ("□", "Knowledge", false),
                    ],
                    theme,
                ))
                .child(navigation_group(
                    "TOOLS",
                    &[
                        ("<>", "Code", false),
                        ("¶", "Markdown", false),
                        (">_", "Terminal", false),
                    ],
                    theme,
                )),
        )
        .child(
            div()
                .id("all-workspaces")
                .mx_3()
                .mb_3()
                .px_3()
                .py_2()
                .flex()
                .items_center()
                .justify_between()
                .rounded(px(2.0))
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.text_muted))
                .cursor_pointer()
                .hover(move |style| {
                    style
                        .bg(rgb(theme.surface_raised))
                        .text_color(rgb(theme.text))
                })
                .child("ALL WORKSPACES")
                .child("⌘⇧W")
                .on_click(cx.listener(|this, _, _, cx| this.show_workspace_index(cx))),
        )
        .when(workspace_menu_open, |this| {
            this.child(workspace_menu(selected.id, workspaces, theme, cx))
        })
}

fn workspace_switcher(
    selected: &WorkspaceSummary,
    theme: Theme,
    cx: &mut Context<RootView>,
) -> impl IntoElement + use<> {
    let name = selected.name.as_str().to_owned();

    div()
        .p_2()
        .border_b_1()
        .border_color(rgb(theme.border))
        .child(
            div()
                .id("workspace-switcher")
                .w_full()
                .px_2()
                .py_2()
                .flex()
                .items_center()
                .gap_2()
                .border_1()
                .border_color(rgb(theme.border))
                .rounded(px(2.0))
                .bg(rgb(theme.canvas))
                .cursor_pointer()
                .hover(move |style| style.border_color(rgb(theme.accent)))
                .child(
                    div()
                        .size(px(22.0))
                        .flex_none()
                        .flex()
                        .items_center()
                        .justify_center()
                        .rounded(px(2.0))
                        .bg(rgb(theme.accent))
                        .text_color(rgb(theme.accent_text))
                        .child("◈"),
                )
                .child(
                    div()
                        .min_w_0()
                        .flex_1()
                        .overflow_hidden()
                        .text_sm()
                        .font_weight(gpui::FontWeight::SEMIBOLD)
                        .child(name),
                )
                .child(
                    div()
                        .flex_none()
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(theme.text_muted))
                        .child("⌄"),
                )
                .on_click(cx.listener(|this, _, _, cx| this.toggle_workspace_menu(cx))),
        )
}

fn workspace_menu(
    selected_id: WorkspaceId,
    workspaces: &[WorkspaceSummary],
    theme: Theme,
    cx: &mut Context<RootView>,
) -> impl IntoElement + use<> {
    let mut options = div()
        .id("workspace-menu-options")
        .max_h(px(280.0))
        .overflow_scroll()
        .flex()
        .flex_col()
        .gap_1();
    for (index, workspace) in workspaces.iter().enumerate() {
        let id = workspace.id;
        let is_selected = id == selected_id;
        let name = workspace.name.as_str().to_owned();
        let path = workspace.root.display().to_string();
        options = options.child(
            div()
                .id(("switch-workspace", index))
                .px_3()
                .py_2()
                .flex()
                .items_center()
                .gap_2()
                .rounded(px(2.0))
                .cursor_pointer()
                .when(is_selected, |this| this.bg(rgb(theme.surface_raised)))
                .hover(move |style| style.bg(rgb(theme.surface_raised)))
                .child(
                    div()
                        .w(px(16.0))
                        .flex_none()
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(if is_selected {
                            theme.success
                        } else {
                            theme.text_muted
                        }))
                        .child(if is_selected { "●" } else { "○" }),
                )
                .child(
                    div()
                        .min_w_0()
                        .flex_1()
                        .flex()
                        .flex_col()
                        .gap_1()
                        .child(div().text_sm().child(name))
                        .child(
                            div()
                                .overflow_hidden()
                                .font_family("Menlo")
                                .text_xs()
                                .text_color(rgb(theme.text_muted))
                                .child(path),
                        ),
                )
                .on_click(cx.listener(move |this, _, _, cx| this.select_workspace(id, cx))),
        );
    }

    div()
        .id("workspace-menu")
        .absolute()
        .top(px(54.0))
        .left(px(8.0))
        .w(px(248.0))
        .p_2()
        .border_1()
        .border_color(rgb(theme.accent))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .shadow_lg()
        .child(options)
        .child(
            div()
                .mt_2()
                .pt_2()
                .border_t_1()
                .border_color(rgb(theme.border))
                .child(
                    div()
                        .id("create-workspace-from-switcher")
                        .px_3()
                        .py_2()
                        .rounded(px(2.0))
                        .text_sm()
                        .text_color(rgb(theme.accent))
                        .cursor_pointer()
                        .hover(move |style| style.bg(rgb(theme.surface_raised)))
                        .child("+  Create new workspace")
                        .on_click(cx.listener(RootView::create_new_workspace)),
                ),
        )
}

fn navigation_group(
    label: &'static str,
    items: &[(&'static str, &'static str, bool)],
    theme: Theme,
) -> impl IntoElement {
    let mut list = div().flex().flex_col().gap_1();
    for (index, (icon, name, active)) in items.iter().copied().enumerate() {
        list = list.child(navigation_item(index, icon, name, active, theme));
    }

    div()
        .flex()
        .flex_col()
        .gap_2()
        .child(
            div()
                .px_2()
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.text_muted))
                .child(label),
        )
        .child(list)
}

fn navigation_item(
    _index: usize,
    icon: &'static str,
    name: &'static str,
    active: bool,
    theme: Theme,
) -> impl IntoElement {
    div()
        .px_2()
        .py_2()
        .flex()
        .items_center()
        .gap_3()
        .rounded(px(2.0))
        .text_sm()
        .text_color(rgb(if active { theme.text } else { theme.text_muted }))
        .when(active, |this| {
            this.bg(rgb(theme.surface_raised))
                .border_l_2()
                .border_color(rgb(theme.accent))
        })
        .child(
            div()
                .w(px(22.0))
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(if active {
                    theme.accent
                } else {
                    theme.text_muted
                }))
                .child(icon),
        )
        .child(name)
}

fn main_panel(selected: &WorkspaceSummary, theme: Theme) -> impl IntoElement {
    let name = selected.name.as_str().to_owned();
    let path = selected.root.display().to_string();

    div()
        .min_w_0()
        .flex_1()
        .h_full()
        .flex()
        .flex_col()
        .child(
            div()
                .h(px(48.0))
                .flex_none()
                .px_5()
                .flex()
                .items_center()
                .justify_between()
                .border_b_1()
                .border_color(rgb(theme.border))
                .bg(rgb(theme.surface))
                .child(
                    div()
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(theme.text_muted))
                        .child("WORKSPACE  /  OVERVIEW"),
                )
                .child(
                    div()
                        .flex()
                        .items_center()
                        .gap_2()
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(theme.success))
                        .child(div().size(px(6.0)).rounded_full().bg(rgb(theme.success)))
                        .child("LOCAL · READY"),
                ),
        )
        .child(
            div()
                .id("workspace-overview-scroll")
                .flex_1()
                .overflow_scroll()
                .px_8()
                .py_8()
                .child(
                    div()
                        .max_w(px(920.0))
                        .flex()
                        .flex_col()
                        .gap_7()
                        .child(
                            div()
                                .flex()
                                .flex_col()
                                .gap_3()
                                .child(
                                    div()
                                        .font_family("Menlo")
                                        .text_xs()
                                        .text_color(rgb(theme.accent))
                                        .child("WORKSPACE · READY"),
                                )
                                .child(div().font_family("Georgia").text_3xl().child(name))
                                .child(
                                    div()
                                        .font_family("Menlo")
                                        .text_sm()
                                        .text_color(rgb(theme.text_muted))
                                        .child(path),
                                ),
                        )
                        .child(
                            div()
                                .pt_5()
                                .border_t_1()
                                .border_color(rgb(theme.border))
                                .flex()
                                .flex_wrap()
                                .gap_3()
                                .child(surface_card(
                                    "REPOSITORIES",
                                    "00 TRACKED",
                                    "Add or clone repositories into the managed workspace.",
                                    theme,
                                ))
                                .child(surface_card(
                                    "WORKTREES",
                                    "00 ACTIVE",
                                    "Isolated branches and agent work will appear here.",
                                    theme,
                                ))
                                .child(surface_card(
                                    "KNOWLEDGE",
                                    "READY",
                                    "Durable project context lives with the workspace.",
                                    theme,
                                )),
                        ),
                ),
        )
}

fn surface_card(
    label: &'static str,
    value: &'static str,
    description: &'static str,
    theme: Theme,
) -> impl IntoElement {
    div()
        .w(px(260.0))
        .min_h(px(144.0))
        .p_4()
        .flex()
        .flex_col()
        .justify_between()
        .border_1()
        .border_color(rgb(theme.border))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .child(
            div()
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.text_muted))
                .child(label),
        )
        .child(
            div()
                .font_family("Georgia")
                .text_2xl()
                .text_color(rgb(theme.text))
                .child(value),
        )
        .child(
            div()
                .text_xs()
                .line_height(px(18.0))
                .text_color(rgb(theme.text_muted))
                .child(description),
        )
}

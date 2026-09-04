use std::sync::Arc;

use gpui::{
    Context, Entity, IntoElement, Render, Window, WindowControlArea, div, prelude::*, px, rgb,
};
use unshell_core::{WorkspaceId, WorkspaceSummary};
use unshell_local::LocalWorkspaceService;
use unshell_ui::{Theme, ThemeId};

use crate::workspace_setup::{WorkspaceCreated, WorkspaceSetupView};

enum Route {
    Setup(Entity<WorkspaceSetupView>),
    WorkspaceList,
    WorkArea,
    StartupError(String),
}

pub struct RootView {
    theme: ThemeId,
    service: Option<Arc<LocalWorkspaceService>>,
    workspaces: Vec<WorkspaceSummary>,
    selected_workspace: Option<WorkspaceId>,
    workspace_menu_open: bool,
    route: Route,
    #[cfg(debug_assertions)]
    pub(crate) show_design_system: bool,
}

impl RootView {
    pub(crate) fn new(
        startup: Result<(Arc<LocalWorkspaceService>, Vec<WorkspaceSummary>), String>,
        cx: &mut Context<Self>,
    ) -> Self {
        match startup {
            Ok((service, workspaces)) => {
                let route = if workspaces.is_empty() {
                    Self::setup_route(service.clone(), cx)
                } else {
                    Route::WorkspaceList
                };
                Self {
                    theme: ThemeId::UnshellDark,
                    service: Some(service),
                    workspaces,
                    selected_workspace: None,
                    workspace_menu_open: false,
                    route,
                    #[cfg(debug_assertions)]
                    show_design_system: false,
                }
            }
            Err(error) => Self {
                theme: ThemeId::UnshellDark,
                service: None,
                workspaces: Vec::new(),
                selected_workspace: None,
                workspace_menu_open: false,
                route: Route::StartupError(error),
                #[cfg(debug_assertions)]
                show_design_system: false,
            },
        }
    }

    fn setup_route(service: Arc<LocalWorkspaceService>, cx: &mut Context<Self>) -> Route {
        let theme = ThemeId::UnshellDark.theme();
        let setup = cx.new(|cx| WorkspaceSetupView::new(service, theme, cx));
        cx.subscribe(&setup, |this, _, event: &WorkspaceCreated, cx| {
            crate::workspace_list::record_created(&mut this.workspaces, event.0.clone());
            this.selected_workspace = None;
            this.workspace_menu_open = false;
            this.route = Route::WorkspaceList;
            cx.notify();
        })
        .detach();
        Route::Setup(setup)
    }

    pub(crate) fn create_new_workspace(
        &mut self,
        _: &gpui::ClickEvent,
        _: &mut Window,
        cx: &mut Context<Self>,
    ) {
        if let Some(service) = self.service.clone() {
            self.selected_workspace = None;
            self.workspace_menu_open = false;
            self.route = Self::setup_route(service, cx);
            cx.notify();
        }
    }

    pub(crate) fn select_workspace(&mut self, id: WorkspaceId, cx: &mut Context<Self>) {
        if resolve_selected_workspace(&self.workspaces, Some(id)).is_some() {
            self.selected_workspace = Some(id);
            self.workspace_menu_open = false;
            self.route = Route::WorkArea;
            cx.notify();
        }
    }

    pub(crate) fn toggle_workspace_menu(&mut self, cx: &mut Context<Self>) {
        self.workspace_menu_open = !self.workspace_menu_open;
        cx.notify();
    }

    pub(crate) fn show_workspace_index(&mut self, cx: &mut Context<Self>) {
        self.selected_workspace = None;
        self.workspace_menu_open = false;
        self.route = Route::WorkspaceList;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn select_theme(&mut self, theme: ThemeId, cx: &mut Context<Self>) {
        self.theme = theme;
        theme.theme().apply_to_gpui_kit(cx);
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn close_design_system(&mut self, cx: &mut Context<Self>) {
        self.show_design_system = false;
        cx.notify();
    }

    fn frame(
        &self,
        theme: Theme,
        window: &Window,
        cx: &mut Context<Self>,
        content: impl IntoElement,
    ) -> impl IntoElement {
        div()
            .size_full()
            .flex()
            .flex_col()
            .bg(rgb(theme.canvas))
            .text_color(rgb(theme.text))
            .child(self.title_bar(theme, window.is_window_active(), cx))
            .child(content)
    }

    fn title_bar(
        &self,
        theme: Theme,
        is_window_active: bool,
        cx: &mut Context<Self>,
    ) -> impl IntoElement {
        let chrome = if is_window_active {
            theme.surface
        } else {
            theme.canvas
        };
        let text = if is_window_active {
            theme.text_muted
        } else {
            theme.border
        };

        div()
            .id("app-title-bar")
            .w_full()
            .h(px(40.0))
            .flex_none()
            .flex()
            .items_center()
            .border_b_1()
            .border_color(rgb(theme.border))
            .bg(rgb(chrome))
            .window_control_area(WindowControlArea::Drag)
            .child(div().w(px(78.0)).flex_none())
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap_2()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(text))
                    .child("◈")
                    .child("UNSHELL")
                    .child(div().w(px(1.0)).h(px(12.0)).bg(rgb(theme.border)))
                    .child("DEVELOPER WORKSPACE"),
            )
            .child(div().flex_1().window_control_area(WindowControlArea::Drag))
            .when(cfg!(debug_assertions), |this| {
                this.child(
                    div()
                        .id("open-design-system")
                        .cursor_pointer()
                        .mr_3()
                        .px_2()
                        .py_1()
                        .rounded(px(2.0))
                        .font_family("Menlo")
                        .text_sm()
                        .text_color(rgb(text))
                        .hover(move |style| {
                            style
                                .bg(rgb(theme.surface_raised))
                                .text_color(rgb(theme.accent))
                        })
                        .child(">_")
                        .on_click(cx.listener(|_this, _, _, _cx| {
                            #[cfg(debug_assertions)]
                            {
                                _this.show_design_system = true;
                                _cx.notify();
                            }
                        })),
                )
            })
            .child(
                div()
                    .pr_4()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(text))
                    .child("LOCAL · READY"),
            )
    }

    fn startup_error(error: &str, theme: Theme) -> impl IntoElement {
        div()
            .flex_1()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap_3()
            .px_8()
            .child(
                div()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.danger))
                    .child("LOCAL DATABASE · UNAVAILABLE"),
            )
            .child(
                div()
                    .font_family("Georgia")
                    .text_2xl()
                    .child("Unshell could not start"),
            )
            .child(
                div()
                    .max_w(px(720.0))
                    .text_sm()
                    .text_color(rgb(theme.text_muted))
                    .child(error.to_owned()),
            )
    }
}

impl Render for RootView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = self.theme.theme();

        #[cfg(debug_assertions)]
        if self.show_design_system {
            let page = crate::design_system::design_system_page(self.theme, cx);
            return self.frame(theme, window, cx, page).into_any_element();
        }

        let content = match &self.route {
            Route::Setup(setup) => setup.clone().into_any_element(),
            Route::WorkspaceList => {
                crate::workspace_list::workspace_list(&self.workspaces, theme, cx)
                    .into_any_element()
            }
            Route::WorkArea => {
                if let Some(workspace) =
                    resolve_selected_workspace(&self.workspaces, self.selected_workspace).cloned()
                {
                    crate::work_area::work_area(
                        &workspace,
                        &self.workspaces,
                        self.workspace_menu_open,
                        theme,
                        cx,
                    )
                    .into_any_element()
                } else {
                    crate::workspace_list::workspace_list(&self.workspaces, theme, cx)
                        .into_any_element()
                }
            }
            Route::StartupError(error) => Self::startup_error(error, theme).into_any_element(),
        };
        self.frame(theme, window, cx, content).into_any_element()
    }
}

fn resolve_selected_workspace(
    workspaces: &[WorkspaceSummary],
    selected: Option<WorkspaceId>,
) -> Option<&WorkspaceSummary> {
    let selected = selected?;
    workspaces.iter().find(|workspace| workspace.id == selected)
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use unshell_core::{WorkspaceId, WorkspaceName, WorkspaceSummary};

    use super::resolve_selected_workspace;

    fn summary(name: &str) -> WorkspaceSummary {
        WorkspaceSummary {
            id: WorkspaceId::new(),
            name: WorkspaceName::new(name).unwrap(),
            root: PathBuf::from("/tmp").join(name),
        }
    }

    #[test]
    fn work_area_requires_a_known_selected_workspace() {
        let known = summary("known");
        let unknown = summary("unknown");
        let workspaces = [known.clone()];

        assert!(resolve_selected_workspace(&workspaces, None).is_none());
        assert!(resolve_selected_workspace(&workspaces, Some(unknown.id)).is_none());
        assert_eq!(
            resolve_selected_workspace(&workspaces, Some(known.id)),
            Some(&known)
        );
    }
}

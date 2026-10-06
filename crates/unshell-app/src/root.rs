use std::sync::Arc;

use gpui::{
    Context, Entity, IntoElement, Render, Window, WindowControlArea, deferred, div, prelude::*, px,
    rgb,
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
    theme_menu_open: bool,
    route: Route,
    #[cfg(debug_assertions)]
    dev_page: Option<crate::design_system::DevPage>,
    #[cfg(debug_assertions)]
    dev_menu_open: bool,
    #[cfg(debug_assertions)]
    kit_preview: crate::design_system::KitPreview,
}

impl RootView {
    pub(crate) fn new(
        startup: Result<(Arc<LocalWorkspaceService>, Vec<WorkspaceSummary>), String>,
        cx: &mut Context<Self>,
    ) -> Self {
        match startup {
            Ok((service, workspaces)) => {
                let theme = ThemeId::UnshellDark;
                let route = if workspaces.is_empty() {
                    Self::setup_route(service.clone(), theme, cx)
                } else {
                    Route::WorkspaceList
                };
                Self {
                    theme,
                    service: Some(service),
                    workspaces,
                    selected_workspace: None,
                    workspace_menu_open: false,
                    theme_menu_open: false,
                    route,
                    #[cfg(debug_assertions)]
                    dev_page: None,
                    #[cfg(debug_assertions)]
                    dev_menu_open: false,
                    #[cfg(debug_assertions)]
                    kit_preview: crate::design_system::KitPreview::Button,
                }
            }
            Err(error) => Self {
                theme: ThemeId::UnshellDark,
                service: None,
                workspaces: Vec::new(),
                selected_workspace: None,
                workspace_menu_open: false,
                theme_menu_open: false,
                route: Route::StartupError(error),
                #[cfg(debug_assertions)]
                dev_page: None,
                #[cfg(debug_assertions)]
                dev_menu_open: false,
                #[cfg(debug_assertions)]
                kit_preview: crate::design_system::KitPreview::Button,
            },
        }
    }

    fn setup_route(
        service: Arc<LocalWorkspaceService>,
        theme: ThemeId,
        cx: &mut Context<Self>,
    ) -> Route {
        let setup = cx.new(|cx| WorkspaceSetupView::new(service, theme.theme(), cx));
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
            self.theme_menu_open = false;
            self.route = Self::setup_route(service, self.theme, cx);
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

    pub(crate) fn select_theme(&mut self, theme: ThemeId, cx: &mut Context<Self>) {
        self.theme = theme;
        self.theme_menu_open = false;
        theme.theme().apply_to_gpui_kit(cx);
        if let Route::Setup(setup) = &self.route {
            setup.update(cx, |setup, cx| setup.set_theme(theme.theme(), cx));
        }
        cx.notify();
    }

    pub(crate) fn toggle_theme_menu(&mut self, cx: &mut Context<Self>) {
        self.theme_menu_open = !self.theme_menu_open;
        #[cfg(debug_assertions)]
        {
            self.dev_menu_open = false;
        }
        cx.notify();
    }

    pub(crate) fn close_theme_menu(&mut self, cx: &mut Context<Self>) {
        self.theme_menu_open = false;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn toggle_dev_menu(&mut self, cx: &mut Context<Self>) {
        self.dev_menu_open = !self.dev_menu_open;
        self.theme_menu_open = false;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn close_dev_menu(&mut self, cx: &mut Context<Self>) {
        self.dev_menu_open = false;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn open_dev_page(
        &mut self,
        page: crate::design_system::DevPage,
        cx: &mut Context<Self>,
    ) {
        self.dev_page = Some(page);
        self.dev_menu_open = false;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn close_dev_page(&mut self, cx: &mut Context<Self>) {
        self.dev_page = None;
        self.dev_menu_open = false;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn select_kit_preview(
        &mut self,
        preview: crate::design_system::KitPreview,
        cx: &mut Context<Self>,
    ) {
        self.kit_preview = preview;
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
            .child(self.theme_control(theme, text, cx))
            .when(cfg!(debug_assertions), |this| {
                this.child(
                    div()
                        .id("dev-menu-anchor")
                        .relative()
                        .mr_3()
                        .child(
                            div()
                                .id("open-dev-menu")
                                .cursor_pointer()
                                .px_2()
                                .py_1()
                                .flex()
                                .items_center()
                                .gap_2()
                                .rounded(px(2.0))
                                .font_family("Menlo")
                                .text_xs()
                                .text_color(rgb(text))
                                .hover(move |style| {
                                    style
                                        .bg(rgb(theme.surface_raised))
                                        .text_color(rgb(theme.accent))
                                })
                                .child(">_ DEV")
                                .child("⌄")
                                .on_click(cx.listener(|_this, _, _, _cx| {
                                    #[cfg(debug_assertions)]
                                    _this.toggle_dev_menu(_cx);
                                })),
                        )
                        .when(
                            cfg!(debug_assertions) && {
                                #[cfg(debug_assertions)]
                                {
                                    self.dev_menu_open
                                }
                                #[cfg(not(debug_assertions))]
                                {
                                    false
                                }
                            },
                            |this| {
                                #[cfg(debug_assertions)]
                                {
                                    this.child(deferred(self.dev_menu(theme, cx)))
                                }
                                #[cfg(not(debug_assertions))]
                                {
                                    this
                                }
                            },
                        ),
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

    fn theme_control(
        &self,
        theme: Theme,
        text: u32,
        cx: &mut Context<Self>,
    ) -> impl IntoElement + use<> {
        div()
            .id("theme-menu-anchor")
            .relative()
            .mr_2()
            .child(
                div()
                    .id("open-theme-menu")
                    .cursor_pointer()
                    .px_2()
                    .py_1()
                    .flex()
                    .items_center()
                    .gap_2()
                    .rounded(px(2.0))
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(text))
                    .hover(move |style| {
                        style
                            .bg(rgb(theme.surface_raised))
                            .text_color(rgb(theme.accent))
                    })
                    .child(div().size(px(8.0)).rounded_full().bg(rgb(theme.accent)))
                    .child(theme.name.to_uppercase())
                    .child("⌄")
                    .on_click(cx.listener(|this, _, _, cx| this.toggle_theme_menu(cx))),
            )
            .when(self.theme_menu_open, |this| {
                this.child(deferred(self.theme_menu(theme, cx)))
            })
    }

    fn theme_menu(&self, theme: Theme, cx: &mut Context<Self>) -> impl IntoElement + use<> {
        let mut options = div().flex().flex_col().gap_1();

        for (index, candidate) in ThemeId::ALL.into_iter().enumerate() {
            let candidate_theme = candidate.theme();
            let selected = self.theme == candidate;
            options = options.child(
                div()
                    .id(("select-app-theme", index))
                    .px_3()
                    .py_2()
                    .flex()
                    .items_center()
                    .gap_3()
                    .rounded(px(2.0))
                    .cursor_pointer()
                    .when(selected, |this| this.bg(rgb(theme.surface_raised)))
                    .hover(move |style| style.bg(rgb(theme.surface_raised)))
                    .child(
                        div()
                            .size(px(12.0))
                            .flex_none()
                            .rounded_full()
                            .bg(rgb(candidate_theme.accent))
                            .border_1()
                            .border_color(rgb(candidate_theme.border)),
                    )
                    .child(
                        div()
                            .min_w_0()
                            .flex_1()
                            .flex()
                            .flex_col()
                            .gap_1()
                            .child(
                                div()
                                    .text_sm()
                                    .font_weight(gpui::FontWeight::SEMIBOLD)
                                    .child(candidate_theme.name),
                            )
                            .child(
                                div()
                                    .font_family("Menlo")
                                    .text_xs()
                                    .text_color(rgb(theme.text_muted))
                                    .child(candidate_theme.description),
                            ),
                    )
                    .child(
                        div()
                            .w(px(16.0))
                            .font_family("Menlo")
                            .text_xs()
                            .text_color(rgb(theme.accent))
                            .child(if selected { "✓" } else { "" }),
                    )
                    .on_click(cx.listener(move |this, _, _, cx| this.select_theme(candidate, cx))),
            );
        }

        div()
            .id("theme-menu")
            .absolute()
            .top(px(31.0))
            .right_0()
            .w(px(320.0))
            .p_2()
            .border_1()
            .border_color(rgb(theme.accent))
            .rounded(px(2.0))
            .bg(rgb(theme.surface))
            .shadow_lg()
            .occlude()
            .on_mouse_down_out(cx.listener(|this, _, _, cx| this.close_theme_menu(cx)))
            .child(
                div()
                    .px_3()
                    .pt_2()
                    .pb_3()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.text_muted))
                    .child("APPLICATION THEME"),
            )
            .child(options)
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

    #[cfg(debug_assertions)]
    fn dev_menu(&self, theme: Theme, cx: &mut Context<Self>) -> impl IntoElement + use<> {
        let mut pages = div().flex().flex_col().gap_1();

        for (index, page) in crate::design_system::DevPage::ALL.into_iter().enumerate() {
            let selected = self.dev_page == Some(page);
            pages = pages.child(
                div()
                    .id(("open-dev-page", index))
                    .px_3()
                    .py_2()
                    .flex()
                    .items_center()
                    .gap_3()
                    .rounded(px(2.0))
                    .cursor_pointer()
                    .when(selected, |this| this.bg(rgb(theme.surface_raised)))
                    .hover(move |style| style.bg(rgb(theme.surface_raised)))
                    .child(
                        div()
                            .w(px(18.0))
                            .flex_none()
                            .font_family("Menlo")
                            .text_xs()
                            .text_color(rgb(if selected {
                                theme.accent
                            } else {
                                theme.text_muted
                            }))
                            .child(if selected { "●" } else { "○" }),
                    )
                    .child(
                        div()
                            .min_w_0()
                            .flex_1()
                            .flex()
                            .flex_col()
                            .gap_1()
                            .child(
                                div()
                                    .text_sm()
                                    .font_weight(gpui::FontWeight::SEMIBOLD)
                                    .child(page.title()),
                            )
                            .child(
                                div()
                                    .font_family("Menlo")
                                    .text_xs()
                                    .text_color(rgb(theme.text_muted))
                                    .child(page.menu_description()),
                            ),
                    )
                    .on_click(cx.listener(move |this, _, _, cx| this.open_dev_page(page, cx))),
            );
        }

        div()
            .id("dev-menu")
            .absolute()
            .top(px(31.0))
            .right_0()
            .w(px(292.0))
            .p_2()
            .border_1()
            .border_color(rgb(theme.accent))
            .rounded(px(2.0))
            .bg(rgb(theme.surface))
            .shadow_lg()
            .occlude()
            .on_mouse_down_out(cx.listener(|this, _, _, cx| this.close_dev_menu(cx)))
            .child(
                div()
                    .px_3()
                    .pt_2()
                    .pb_3()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.text_muted))
                    .child("DEVELOPMENT PAGES"),
            )
            .child(pages)
    }
}

impl Render for RootView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = self.theme.theme();

        #[cfg(debug_assertions)]
        if let Some(active_page) = self.dev_page {
            let page = crate::design_system::playground_page(
                self.theme,
                active_page,
                self.kit_preview,
                cx,
            );
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

use std::{path::PathBuf, sync::Arc};

use gpui::{
    Context, Entity, EventEmitter, PathPromptOptions, Render, Task, Window, div, prelude::*, px,
    rgb,
};
use unshell_core::{WorkspaceName, WorkspaceRequest, WorkspaceSummary};
use unshell_local::LocalWorkspaceService;
use unshell_ui::{Changed, TextInput, Theme};

pub(crate) struct WorkspaceCreated(pub(crate) WorkspaceSummary);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum SetupPhase {
    Editing,
    SelectingDirectory,
    Creating,
    Failed,
}

pub(crate) struct WorkspaceSetupView {
    service: Arc<LocalWorkspaceService>,
    theme: Theme,
    name_input: Entity<TextInput>,
    parent: Option<PathBuf>,
    phase: SetupPhase,
    error: Option<String>,
    pending_task: Option<Task<()>>,
}

impl WorkspaceSetupView {
    pub(crate) fn new(
        service: Arc<LocalWorkspaceService>,
        theme: Theme,
        cx: &mut Context<Self>,
    ) -> Self {
        let name_input = cx.new(|cx| TextInput::new("Workspace name", theme, cx));
        cx.subscribe(&name_input, |this, _, _: &Changed, cx| {
            if this.phase == SetupPhase::Failed {
                this.phase = SetupPhase::Editing;
                this.error = None;
            }
            cx.notify();
        })
        .detach();
        Self {
            service,
            theme,
            name_input,
            parent: None,
            phase: SetupPhase::Editing,
            error: None,
            pending_task: None,
        }
    }

    pub(crate) fn set_theme(&mut self, theme: Theme, cx: &mut Context<Self>) {
        self.theme = theme;
        self.name_input
            .update(cx, |input, cx| input.set_theme(theme, cx));
        cx.notify();
    }

    fn select_parent(&mut self, _: &gpui::ClickEvent, _: &mut Window, cx: &mut Context<Self>) {
        if matches!(
            self.phase,
            SetupPhase::SelectingDirectory | SetupPhase::Creating
        ) {
            return;
        }
        self.phase = SetupPhase::SelectingDirectory;
        self.error = None;
        self.name_input
            .update(cx, |input, cx| input.set_disabled(true, cx));
        cx.notify();

        let receiver = cx.prompt_for_paths(PathPromptOptions {
            files: false,
            directories: true,
            multiple: false,
            prompt: Some("Select parent folder".into()),
        });
        self.pending_task = Some(cx.spawn(async move |this, cx| {
            let result = receiver.await;
            let _ = this.update(cx, |this, cx| {
                this.phase = SetupPhase::Editing;
                this.name_input
                    .update(cx, |input, cx| input.set_disabled(false, cx));
                match result {
                    Ok(Ok(Some(paths))) => this.parent = paths.into_iter().next(),
                    Ok(Ok(None)) => {}
                    Ok(Err(error)) => {
                        this.phase = SetupPhase::Failed;
                        this.error = Some(format!("Could not open the folder picker: {error}"));
                    }
                    Err(_) => {
                        this.phase = SetupPhase::Failed;
                        this.error = Some("The folder picker closed unexpectedly.".into());
                    }
                }
                cx.notify();
            });
        }));
    }

    fn validated_name(&self, cx: &Context<Self>) -> Result<WorkspaceName, String> {
        WorkspaceName::new(self.name_input.read(cx).value().to_owned())
            .map_err(|error| error.to_string())
    }

    fn create_workspace(&mut self, _: &gpui::ClickEvent, _: &mut Window, cx: &mut Context<Self>) {
        if matches!(
            self.phase,
            SetupPhase::SelectingDirectory | SetupPhase::Creating
        ) {
            return;
        }
        let Some(parent) = self.parent.clone() else {
            self.phase = SetupPhase::Failed;
            self.error = Some("Select a parent folder first.".into());
            cx.notify();
            return;
        };
        let name = match self.validated_name(cx) {
            Ok(name) => name,
            Err(error) => {
                self.phase = SetupPhase::Failed;
                self.error = Some(error);
                cx.notify();
                return;
            }
        };

        self.phase = SetupPhase::Creating;
        self.error = None;
        self.name_input
            .update(cx, |input, cx| input.set_disabled(true, cx));
        cx.notify();

        let service = self.service.clone();
        let task = cx
            .background_executor()
            .spawn(async move { service.create_workspace(WorkspaceRequest { parent, name }) });
        self.pending_task = Some(cx.spawn(async move |this, cx| {
            let result = task.await;
            let _ = this.update(cx, |this, cx| match result {
                Ok(workspace) => cx.emit(WorkspaceCreated(workspace)),
                Err(error) => {
                    this.phase = SetupPhase::Failed;
                    this.error = Some(error.to_string());
                    this.name_input
                        .update(cx, |input, cx| input.set_disabled(false, cx));
                    cx.notify();
                }
            });
        }));
    }

    fn can_create(&self, cx: &Context<Self>) -> bool {
        is_form_submittable(
            self.parent.as_deref(),
            self.name_input.read(cx).value(),
            self.phase,
        )
    }

    fn field_label(&self, index: &'static str, label: &'static str) -> impl IntoElement {
        div()
            .flex()
            .items_center()
            .gap_2()
            .font_family("Menlo")
            .text_xs()
            .text_color(rgb(self.theme.text_muted))
            .child(div().text_color(rgb(self.theme.accent)).child(index))
            .child(label)
    }
}

fn is_form_submittable(parent: Option<&std::path::Path>, name: &str, phase: SetupPhase) -> bool {
    matches!(phase, SetupPhase::Editing | SetupPhase::Failed)
        && parent.is_some()
        && WorkspaceName::new(name).is_ok()
}

impl EventEmitter<WorkspaceCreated> for WorkspaceSetupView {}

impl Render for WorkspaceSetupView {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = self.theme;
        let busy = matches!(
            self.phase,
            SetupPhase::SelectingDirectory | SetupPhase::Creating
        );
        let can_create = self.can_create(cx);
        let parent = self
            .parent
            .as_ref()
            .map(|path| path.display().to_string())
            .unwrap_or_else(|| "No parent folder selected".into());
        let browse_label = if self.phase == SetupPhase::SelectingDirectory {
            "Selecting…"
        } else {
            "Choose folder"
        };
        let create_label = if self.phase == SetupPhase::Creating {
            "Creating workspace…"
        } else {
            "Create workspace"
        };

        div()
            .id("workspace-setup")
            .flex_1()
            .w_full()
            .flex()
            .items_center()
            .justify_center()
            .px_8()
            .py_8()
            .bg(rgb(theme.canvas))
            .child(
                div()
                    .w_full()
                    .max_w(px(720.0))
                    .flex()
                    .flex_col()
                    .gap_6()
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap_2()
                            .child(
                                div()
                                    .font_family("Menlo")
                                    .text_xs()
                                    .text_color(rgb(theme.accent))
                                    .child("01 // WORKSPACE SETUP"),
                            )
                            .child(
                                div()
                                    .font_family("Georgia")
                                    .text_3xl()
                                    .child("Create your workspace"),
                            )
                            .child(
                                div()
                                    .text_sm()
                                    .line_height(px(21.0))
                                    .text_color(rgb(theme.text_muted))
                                    .child("Unshell creates a managed developer workspace for repositories, worktrees, knowledge, and a reproducible Nix environment."),
                            ),
                    )
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap_2()
                            .child(self.field_label("A", "PARENT DIRECTORY"))
                            .child(
                                div()
                                    .flex()
                                    .items_center()
                                    .gap_3()
                                    .child(
                                        div()
                                            .id("workspace-parent-path")
                                            .flex_1()
                                            .min_w_0()
                                            .px_3()
                                            .py_2()
                                            .border_1()
                                            .border_color(rgb(theme.border))
                                            .rounded(px(2.0))
                                            .bg(rgb(theme.surface))
                                            .font_family("Menlo")
                                            .text_sm()
                                            .text_color(rgb(theme.text_muted))
                                            .overflow_hidden()
                                            .child(parent),
                                    )
                                    .child(
                                        div()
                                            .id("workspace-parent-select")
                                            .px_4()
                                            .py_2()
                                            .border_1()
                                            .border_color(rgb(theme.border))
                                            .rounded(px(2.0))
                                            .text_sm()
                                            .text_color(rgb(if busy { theme.border } else { theme.text }))
                                            .when(!busy, |this| {
                                                this.cursor_pointer()
                                                    .hover(move |style| style.bg(rgb(theme.surface_raised)).border_color(rgb(theme.accent)))
                                                    .on_click(cx.listener(Self::select_parent))
                                            })
                                            .child(browse_label),
                                    ),
                            ),
                    )
                    .child(
                        div()
                            .flex()
                            .flex_col()
                            .gap_2()
                            .child(self.field_label("B", "WORKSPACE NAME"))
                            .child(self.name_input.clone()),
                    )
                    .when_some(self.error.clone(), |this, error| {
                        this.child(
                            div()
                                .id("workspace-create-error")
                                .px_3()
                                .py_2()
                                .border_1()
                                .border_color(rgb(theme.danger))
                                .bg(rgb(theme.surface))
                                .font_family("Menlo")
                                .text_xs()
                                .text_color(rgb(theme.danger))
                                .child(error),
                        )
                    })
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .justify_between()
                            .pt_4()
                            .border_t_1()
                            .border_color(rgb(theme.border))
                            .child(
                                div()
                                    .font_family("Menlo")
                                    .text_xs()
                                    .text_color(rgb(theme.text_muted))
                                    .child("CREATE-ONLY · EXISTING PATHS ARE NEVER MODIFIED"),
                            )
                            .child(
                                div()
                                    .id("workspace-create")
                                    .px_5()
                                    .py_2()
                                    .rounded(px(2.0))
                                    .bg(rgb(if can_create { theme.accent } else { theme.surface_raised }))
                                    .text_color(rgb(if can_create { theme.accent_text } else { theme.border }))
                                    .text_sm()
                                    .font_weight(gpui::FontWeight::SEMIBOLD)
                                    .when(can_create, |this| {
                                        this.cursor_pointer().on_click(cx.listener(Self::create_workspace))
                                    })
                                    .child(create_label),
                            ),
                    ),
            )
    }
}

#[cfg(test)]
mod tests {
    use std::path::Path;

    use super::{SetupPhase, is_form_submittable};

    #[test]
    fn form_requires_a_parent_and_valid_name_while_editable() {
        let parent = Path::new("/tmp");
        assert!(is_form_submittable(
            Some(parent),
            "Café workspace",
            SetupPhase::Editing
        ));
        assert!(!is_form_submittable(
            None,
            "Café workspace",
            SetupPhase::Editing
        ));
        assert!(!is_form_submittable(
            Some(parent),
            "../escape",
            SetupPhase::Editing
        ));
        assert!(!is_form_submittable(
            Some(parent),
            "Café workspace",
            SetupPhase::Creating
        ));
        assert!(!is_form_submittable(
            Some(parent),
            "Café workspace",
            SetupPhase::SelectingDirectory
        ));
    }
}

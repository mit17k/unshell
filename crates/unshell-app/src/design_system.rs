use gpui::{
    Context, IntoElement, ParentElement, StatefulInteractiveElement, Styled, div, prelude::*, px,
    rgb,
};
use unshell_ui::{Theme, ThemeId};

pub(crate) fn design_system_page(
    active: ThemeId,
    cx: &mut Context<crate::RootView>,
) -> impl IntoElement + use<> {
    let theme = active.theme();
    div()
        .id("design-system-scroll")
        .flex_1()
        .w_full()
        .overflow_scroll()
        .bg(rgb(theme.canvas))
        .text_color(rgb(theme.text))
        .font_family("System UI")
        .child(page_header(theme, cx))
        .child(
            div()
                .max_w(px(1360.0))
                .mx_auto()
                .px_8()
                .py_8()
                .flex()
                .flex_col()
                .gap_8()
                .child(theme_picker(active, theme, cx))
                .child(typography_section(theme))
                .child(component_section(theme))
                .child(status_section(theme)),
        )
}

fn page_header(theme: Theme, cx: &mut Context<crate::RootView>) -> impl IntoElement {
    div()
        .w_full()
        .border_b_1()
        .border_color(rgb(theme.border))
        .bg(rgb(theme.surface))
        .child(
            div()
                .max_w(px(1360.0))
                .mx_auto()
                .px_8()
                .py_4()
                .flex()
                .items_center()
                .justify_between()
                .child(
                    div()
                        .flex()
                        .items_center()
                        .gap_3()
                        .child(div().text_color(rgb(theme.accent)).text_xl().child("◈"))
                        .child(
                            div()
                                .flex()
                                .flex_col()
                                .child(
                                    div()
                                        .text_sm()
                                        .font_weight(gpui::FontWeight::SEMIBOLD)
                                        .child("UNSHELL / DESIGN LANGUAGE"),
                                )
                                .child(
                                    div()
                                        .text_xs()
                                        .text_color(rgb(theme.text_muted))
                                        .child("development preview · semantic tokens"),
                                ),
                        ),
                )
                .child(
                    div()
                        .id("close-design-system")
                        .cursor_pointer()
                        .px_3()
                        .py_2()
                        .border_1()
                        .border_color(rgb(theme.border))
                        .rounded(px(2.0))
                        .text_xs()
                        .text_color(rgb(theme.text_muted))
                        .hover(move |style| {
                            style
                                .bg(rgb(theme.surface_raised))
                                .text_color(rgb(theme.text))
                        })
                        .child("ESC  CLOSE")
                        .on_click(cx.listener(|this, _, _, cx| this.close_design_system(cx))),
                ),
        )
}

fn theme_picker(
    active: ThemeId,
    theme: Theme,
    cx: &mut Context<crate::RootView>,
) -> impl IntoElement {
    let mut theme_grid = div().flex().flex_wrap().gap_3();

    for (index, candidate) in ThemeId::ALL.into_iter().enumerate() {
        let candidate_theme = candidate.theme();
        let is_active = candidate == active;
        let border = if is_active {
            theme.accent
        } else {
            theme.border
        };
        let label = if is_active { "ACTIVE" } else { "SELECT" };
        theme_grid = theme_grid.child(
            div()
                .id(("theme", index))
                .cursor_pointer()
                .w(px(236.0))
                .p_3()
                .border_1()
                .border_color(rgb(border))
                .rounded(px(2.0))
                .bg(rgb(theme.surface))
                .hover(move |style| {
                    style
                        .bg(rgb(theme.surface_raised))
                        .border_color(rgb(theme.accent))
                })
                .child(div().h(px(6.0)).w_full().bg(rgb(candidate_theme.accent)))
                .child(
                    div()
                        .mt_3()
                        .flex()
                        .justify_between()
                        .items_start()
                        .child(
                            div()
                                .text_sm()
                                .font_weight(gpui::FontWeight::SEMIBOLD)
                                .child(candidate_theme.name),
                        )
                        .child(
                            div()
                                .text_xs()
                                .text_color(rgb(if is_active {
                                    theme.accent
                                } else {
                                    theme.text_muted
                                }))
                                .child(label),
                        ),
                )
                .child(
                    div()
                        .mt_2()
                        .text_xs()
                        .line_height(px(17.0))
                        .text_color(rgb(theme.text_muted))
                        .child(candidate_theme.description),
                )
                .on_click(cx.listener(move |this, _, _, cx| this.select_theme(candidate, cx))),
        );
    }
    div()
        .flex()
        .flex_col()
        .gap_4()
        .child(section_label(
            theme,
            "01 // THEMES",
            "Theme support is role-based. Components inherit intent, never a fixed palette.",
        ))
        .child(theme_grid)
}

fn typography_section(theme: Theme) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_4()
        .child(section_label(theme, "02 // TYPE & HIERARCHY", "Editorial emphasis meets operational clarity: display language for decisions, mono language for evidence."))
        .child(
            div()
                .flex()
                .flex_wrap()
                .gap_4()
                .child(specimen_card(theme, "DISPLAY / ASSERTION", div().text_3xl().font_family("Georgia").child("Build with intent."), "Use for views, decisive actions, and major system states."))
                .child(specimen_card(theme, "UI / WORKSPACE", div().text_xl().font_weight(gpui::FontWeight::SEMIBOLD).child("Focused, legible, native."), "The everyday interface voice for panes, controls, and content."))
                .child(specimen_card(theme, "MONO / EVIDENCE", div().font_family("Menlo").text_sm().child("agent: ready  ·  14 files indexed"), "For commands, paths, metadata, and machine-readable state.")),
        )
}

fn component_section(theme: Theme) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_4()
        .child(section_label(theme, "03 // COMPONENTS", "Fine rules, low-radius surfaces, and compact metadata create hierarchy without ornamental chrome."))
        .child(
            div()
                .flex()
                .flex_wrap()
                .gap_4()
                .child(action_card(theme))
                .child(form_field_card(theme))
                .child(command_card(theme))
                .child(metric_card(theme)),
        )
}

fn form_field_card(theme: Theme) -> impl IntoElement {
    specimen_card(
        theme,
        "TEXT INPUT / FORM",
        div()
            .w_full()
            .px_3()
            .py_2()
            .border_1()
            .border_color(rgb(theme.accent))
            .bg(rgb(theme.canvas))
            .rounded(px(2.0))
            .font_family("Menlo")
            .text_sm()
            .child("my-workspace"),
        "Focused fields use semantic border and text roles; validation remains visible beside the form.",
    )
}

fn action_card(theme: Theme) -> impl IntoElement {
    specimen_card(
        theme,
        "ACTIONS",
        div()
            .flex()
            .items_center()
            .gap_3()
            .child(
                div()
                    .px_4()
                    .py_2()
                    .rounded(px(2.0))
                    .bg(rgb(theme.accent))
                    .text_color(rgb(theme.accent_text))
                    .text_sm()
                    .font_weight(gpui::FontWeight::SEMIBOLD)
                    .child("Start session"),
            )
            .child(
                div()
                    .px_4()
                    .py_2()
                    .rounded(px(2.0))
                    .border_1()
                    .border_color(rgb(theme.border))
                    .text_sm()
                    .text_color(rgb(theme.text_muted))
                    .child("Review diff"),
            ),
        "One decisive filled action; supporting actions remain outlined.",
    )
}

fn command_card(theme: Theme) -> impl IntoElement {
    specimen_card(
        theme,
        "COMMAND / OUTPUT",
        div()
            .font_family("Menlo")
            .text_sm()
            .px_3()
            .py_3()
            .border_1()
            .border_color(rgb(theme.border))
            .bg(rgb(theme.canvas))
            .rounded(px(2.0))
            .child("$ unshell agent run --review"),
        "Terminal-shaped evidence is contained, calm, and directly useful.",
    )
}

fn metric_card(theme: Theme) -> impl IntoElement {
    specimen_card(
        theme,
        "TELEMETRY",
        div()
            .flex()
            .gap_4()
            .child(metric(theme, "12", "AGENTS"))
            .child(metric(theme, "04", "DIFFS"))
            .child(metric(theme, "28", "TASKS")),
        "Small numerical proofs make the workspace feel like an instrument.",
    )
}

fn metric(theme: Theme, value: &'static str, label: &'static str) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_1()
        .child(
            div()
                .text_lg()
                .font_family("Menlo")
                .text_color(rgb(theme.accent))
                .child(value),
        )
        .child(
            div()
                .text_xs()
                .font_family("Menlo")
                .text_color(rgb(theme.text_muted))
                .child(label),
        )
}

fn status_section(theme: Theme) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_4()
        .child(section_label(
            theme,
            "04 // SYSTEM STATUS",
            "Semantic states communicate outcome independently from the selected theme.",
        ))
        .child(
            div()
                .flex()
                .flex_wrap()
                .gap_3()
                .child(status_badge(
                    theme,
                    theme.success,
                    "READY",
                    "Workspace services are healthy",
                ))
                .child(status_badge(
                    theme,
                    theme.warning,
                    "WAITING",
                    "Agent needs a decision",
                ))
                .child(status_badge(
                    theme,
                    theme.danger,
                    "BLOCKED",
                    "A task cannot proceed",
                )),
        )
        .child(
            div()
                .pt_6()
                .pb_3()
                .border_t_1()
                .border_color(rgb(theme.border))
                .text_xs()
                .font_family("Menlo")
                .text_color(rgb(theme.text_muted))
                .child(
                    "DESIGN LANGUAGE · development-only preview · release builds omit this route",
                ),
        )
}

fn status_badge(
    theme: Theme,
    tone: u32,
    label: &'static str,
    description: &'static str,
) -> impl IntoElement {
    div()
        .w(px(236.0))
        .p_3()
        .border_1()
        .border_color(rgb(theme.border))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .child(
            div()
                .flex()
                .items_center()
                .gap_2()
                .child(div().size(px(8.0)).bg(rgb(tone)).rounded_full())
                .child(
                    div()
                        .text_xs()
                        .font_family("Menlo")
                        .text_color(rgb(tone))
                        .child(label),
                ),
        )
        .child(
            div()
                .mt_2()
                .text_xs()
                .text_color(rgb(theme.text_muted))
                .child(description),
        )
}

fn section_label(theme: Theme, index: &'static str, description: &'static str) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_2()
        .child(
            div()
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.accent))
                .child(index),
        )
        .child(
            div()
                .text_sm()
                .text_color(rgb(theme.text_muted))
                .child(description),
        )
}

fn specimen_card(
    theme: Theme,
    label: &'static str,
    specimen: impl IntoElement,
    description: &'static str,
) -> impl IntoElement {
    div()
        .w(px(360.0))
        .min_h(px(180.0))
        .p_4()
        .flex()
        .flex_col()
        .justify_between()
        .gap_4()
        .border_1()
        .border_color(rgb(theme.border))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .child(
            div()
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.accent))
                .child(label),
        )
        .child(div().flex_1().flex().items_center().child(specimen))
        .child(
            div()
                .text_xs()
                .line_height(px(17.0))
                .text_color(rgb(theme.text_muted))
                .child(description),
        )
}

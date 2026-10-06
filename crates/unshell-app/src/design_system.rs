use gpui::{
    Context, IntoElement, Keystroke, ParentElement, StatefulInteractiveElement, Styled, div,
    prelude::*, px, rgb,
};
use unshell_ui::{
    Theme, ThemeId,
    component::{
        Disableable as _, Icon, IconName, Sizable as _,
        accordion::Accordion,
        alert::Alert,
        avatar::Avatar,
        badge::Badge,
        breadcrumb::Breadcrumb,
        button::{Button, ButtonVariants as _, Toggle},
        checkbox::Checkbox,
        group_box::{GroupBox, GroupBoxVariants as _},
        kbd::Kbd,
        label::Label,
        link::Link,
        pagination::Pagination,
        progress::Progress,
        radio::Radio,
        rating::Rating,
        separator::Separator,
        shimmer::ShimmerText,
        skeleton::Skeleton,
        spinner::Spinner,
        stepper::{Stepper, StepperItem},
        switch::Switch,
        tab::{Tab, TabBar},
        tag::Tag,
    },
};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum DevPage {
    GpuiKit,
    UnshellUi,
}

impl DevPage {
    pub(crate) const ALL: [Self; 2] = [Self::GpuiKit, Self::UnshellUi];

    pub(crate) const fn title(self) -> &'static str {
        match self {
            Self::GpuiKit => "GPUI Kit basics",
            Self::UnshellUi => "Unshell UI",
        }
    }

    pub(crate) const fn menu_description(self) -> &'static str {
        match self {
            Self::GpuiKit => "upstream primitives & states",
            Self::UnshellUi => "product patterns & themes",
        }
    }

    const fn eyebrow(self) -> &'static str {
        match self {
            Self::GpuiKit => "GPUI KIT / BASIC COMPONENTS",
            Self::UnshellUi => "UNSHELL / CUSTOM UI",
        }
    }

    const fn description(self) -> &'static str {
        match self {
            Self::GpuiKit => "Live upstream primitives rendered through Unshell's semantic theme.",
            Self::UnshellUi => {
                "Product-specific patterns, semantic roles, and composed workspace surfaces."
            }
        }
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum KitPreview {
    Accordion,
    Alert,
    Avatar,
    Badge,
    Breadcrumb,
    Button,
    Checkbox,
    GroupBox,
    Icon,
    Kbd,
    Label,
    Link,
    Pagination,
    Progress,
    Radio,
    Rating,
    Separator,
    Stepper,
    Switch,
    Tab,
    Tag,
    Toggle,
    Shimmer,
    Skeleton,
    Spinner,
}

impl KitPreview {
    pub(crate) const ALL: [Self; 25] = [
        Self::Button,
        Self::Toggle,
        Self::Link,
        Self::Checkbox,
        Self::Radio,
        Self::Rating,
        Self::Switch,
        Self::Alert,
        Self::Progress,
        Self::Breadcrumb,
        Self::Pagination,
        Self::Stepper,
        Self::Tab,
        Self::Accordion,
        Self::Avatar,
        Self::Badge,
        Self::GroupBox,
        Self::Icon,
        Self::Kbd,
        Self::Label,
        Self::Separator,
        Self::Tag,
        Self::Shimmer,
        Self::Skeleton,
        Self::Spinner,
    ];

    pub(crate) const fn title(self) -> &'static str {
        match self {
            Self::Accordion => "Accordion",
            Self::Alert => "Alert",
            Self::Avatar => "Avatar",
            Self::Badge => "Badge",
            Self::Breadcrumb => "Breadcrumb",
            Self::Button => "Button",
            Self::Checkbox => "Checkbox",
            Self::GroupBox => "GroupBox",
            Self::Icon => "Icon",
            Self::Kbd => "Kbd",
            Self::Label => "Label",
            Self::Link => "Link",
            Self::Pagination => "Pagination",
            Self::Progress => "Progress",
            Self::Radio => "Radio",
            Self::Rating => "Rating",
            Self::Separator => "Separator",
            Self::Stepper => "Stepper",
            Self::Switch => "Switch",
            Self::Tab => "Tabs",
            Self::Tag => "Tag",
            Self::Toggle => "Toggle",
            Self::Shimmer => "Shimmer",
            Self::Skeleton => "Skeleton",
            Self::Spinner => "Spinner",
        }
    }

    const fn group(self) -> &'static str {
        match self {
            Self::Button | Self::Toggle | Self::Link => "ACTIONS",
            Self::Checkbox | Self::Radio | Self::Rating | Self::Switch => "SELECTION",
            Self::Alert | Self::Progress | Self::Spinner => "FEEDBACK",
            Self::Breadcrumb | Self::Pagination | Self::Stepper | Self::Tab => "NAVIGATION",
            Self::Shimmer | Self::Skeleton => "MOTION",
            _ => "CONTENT & LAYOUT",
        }
    }

    const fn description(self) -> &'static str {
        match self {
            Self::Accordion => "Expandable disclosure sections for compact information hierarchy.",
            Self::Alert => "Semantic messages for information, success, warning, and failure.",
            Self::Avatar => "Identity represented by initials or an image fallback.",
            Self::Badge => "A compact count attached to another control.",
            Self::Breadcrumb => "Hierarchical location and navigation context.",
            Self::Button => "Primary, secondary, status, ghost, and link actions.",
            Self::Checkbox => "Independent binary selection.",
            Self::GroupBox => "A titled container for related controls.",
            Self::Icon => "Bundled semantic interface symbols.",
            Self::Kbd => "Platform-aware keyboard shortcut notation.",
            Self::Label => "Primary content paired with supporting metadata.",
            Self::Link => "Inline navigation or secondary action text.",
            Self::Pagination => "Navigation across a bounded page collection.",
            Self::Progress => "Determinate completion feedback.",
            Self::Radio => "Single selection from a small option set.",
            Self::Rating => "A discrete visual rating value.",
            Self::Separator => "Visual grouping for adjacent content.",
            Self::Stepper => "Progress through a defined sequence of stages.",
            Self::Switch => "Immediate on/off setting.",
            Self::Tab => "Switch between peer content surfaces.",
            Self::Tag => "Compact semantic state or classification.",
            Self::Toggle => "A button with persistent selected state.",
            Self::Shimmer => "Animated text treatment for active work.",
            Self::Skeleton => "Animated placeholder geometry for loading content.",
            Self::Spinner => "Indeterminate activity indicator.",
        }
    }
}

pub(crate) fn playground_page(
    active: ThemeId,
    page: DevPage,
    kit_preview: KitPreview,
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
        .child(page_header(page, theme, cx))
        .child(
            div()
                .max_w(px(1360.0))
                .mx_auto()
                .px_8()
                .py_8()
                .flex()
                .flex_col()
                .gap_8()
                .child(match page {
                    DevPage::GpuiKit => gpui_kit_page(theme, kit_preview, cx).into_any_element(),
                    DevPage::UnshellUi => unshell_ui_page(theme).into_any_element(),
                }),
        )
}

fn page_header(page: DevPage, theme: Theme, cx: &mut Context<crate::RootView>) -> impl IntoElement {
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
                                        .child(page.eyebrow()),
                                )
                                .child(
                                    div()
                                        .text_xs()
                                        .text_color(rgb(theme.text_muted))
                                        .child(page.description()),
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
                        .child("CLOSE  ×")
                        .on_click(cx.listener(|this, _, _, cx| this.close_dev_page(cx))),
                ),
        )
}

fn gpui_kit_page(
    theme: Theme,
    selected: KitPreview,
    cx: &mut Context<crate::RootView>,
) -> impl IntoElement + use<> {
    div()
        .flex()
        .flex_col()
        .gap_8()
        .child(kit_overview(theme))
        .child(gpui_kit_gallery(selected, theme, cx))
        .child(page_footer(
            theme,
            "GPUI KIT BASICS · development-only preview · release builds omit this route",
        ))
}

fn unshell_ui_page(theme: Theme) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_8()
        .child(typography_section(theme))
        .child(component_section(theme))
        .child(status_section(theme))
        .child(page_footer(
            theme,
            "UNSHELL UI · development-only preview · release builds omit this route",
        ))
}

fn kit_overview(theme: Theme) -> impl IntoElement {
    div()
        .p_4()
        .flex()
        .items_center()
        .justify_between()
        .gap_6()
        .border_1()
        .border_color(rgb(theme.border))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .child(
            div()
                .min_w_0()
                .flex()
                .flex_col()
                .gap_2()
                .child(
                    div()
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(theme.accent))
                        .child("UPSTREAM COMPONENT BASELINE"),
                )
                .child(
                    div()
                        .max_w(px(760.0))
                        .text_sm()
                        .line_height(px(20.0))
                        .text_color(rgb(theme.text_muted))
                        .child("Inspect rendered GPUI Kit primitives here before composing them into Unshell-specific patterns. The page stays idle between interactions; motion-heavy components belong in focused, opt-in specimens."),
                ),
        )
        .child(
            div()
                .flex_none()
                .px_3()
                .py_2()
                .border_1()
                .border_color(rgb(theme.border))
                .rounded(px(2.0))
                .font_family("Menlo")
                .text_xs()
                .text_color(rgb(theme.text_muted))
                .child(format!("THEME · {}", theme.name.to_uppercase())),
        )
}

fn typography_section(theme: Theme) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap_4()
        .child(section_label(theme, "01 // TYPE & HIERARCHY", "Editorial emphasis meets operational clarity: display language for decisions, mono language for evidence."))
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
        .child(section_label(theme, "02 // COMPOSED COMPONENTS", "Fine rules, low-radius surfaces, and compact metadata create hierarchy without ornamental chrome."))
        .child(
            div()
                .flex()
                .flex_wrap()
                .gap_4()
                .child(action_card(theme))
                .child(form_field_card(theme))
                .child(workspace_row_card(theme))
                .child(workspace_switcher_card(theme))
                .child(command_card(theme))
                .child(metric_card(theme)),
        )
}

fn gpui_kit_gallery(
    selected: KitPreview,
    theme: Theme,
    cx: &mut Context<crate::RootView>,
) -> impl IntoElement + use<> {
    let mut navigation = div().flex().flex_col().gap_1();
    let mut previous_group = "";

    for (index, preview) in KitPreview::ALL.into_iter().enumerate() {
        let group = preview.group();
        if group != previous_group {
            navigation = navigation.child(
                div()
                    .when(index > 0, |this| this.mt_3())
                    .px_2()
                    .py_1()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.text_muted))
                    .child(group),
            );
            previous_group = group;
        }

        let is_selected = preview == selected;
        navigation = navigation.child(
            div()
                .id(("kit-preview", index))
                .px_2()
                .py_2()
                .flex()
                .items_center()
                .justify_between()
                .rounded(px(2.0))
                .cursor_pointer()
                .text_sm()
                .text_color(rgb(if is_selected {
                    theme.text
                } else {
                    theme.text_muted
                }))
                .when(is_selected, |this| {
                    this.bg(rgb(theme.surface_raised))
                        .border_l_2()
                        .border_color(rgb(theme.accent))
                })
                .hover(move |style| {
                    style
                        .bg(rgb(theme.surface_raised))
                        .text_color(rgb(theme.text))
                })
                .child(preview.title())
                .when(
                    matches!(
                        preview,
                        KitPreview::Shimmer | KitPreview::Skeleton | KitPreview::Spinner
                    ),
                    |this| {
                        this.child(
                            div()
                                .font_family("Menlo")
                                .text_xs()
                                .text_color(rgb(theme.warning))
                                .child("MOTION"),
                        )
                    },
                )
                .on_click(cx.listener(move |this, _, _, cx| this.select_kit_preview(preview, cx))),
        );
    }

    div()
        .flex()
        .flex_col()
        .gap_4()
        .child(section_label(
            theme,
            "01 // COMPONENT GALLERY",
            "Select a component to mount its real GPUI Kit specimen. Only one preview is active, so animated components cannot keep the entire catalog repainting.",
        ))
        .child(
            div()
                .flex()
                .items_start()
                .gap_5()
                .child(
                    div()
                        .w(px(216.0))
                        .flex_none()
                        .p_2()
                        .border_1()
                        .border_color(rgb(theme.border))
                        .rounded(px(2.0))
                        .bg(rgb(theme.surface))
                        .child(navigation),
                )
                .child(kit_preview_panel(selected, theme)),
        )
}

fn kit_preview_panel(preview: KitPreview, theme: Theme) -> impl IntoElement {
    div()
        .min_w_0()
        .flex_1()
        .min_h(px(520.0))
        .border_1()
        .border_color(rgb(theme.border))
        .rounded(px(2.0))
        .bg(rgb(theme.surface))
        .child(
            div()
                .px_5()
                .py_4()
                .flex()
                .items_start()
                .justify_between()
                .gap_6()
                .border_b_1()
                .border_color(rgb(theme.border))
                .child(
                    div()
                        .flex()
                        .flex_col()
                        .gap_2()
                        .child(
                            div()
                                .text_lg()
                                .font_weight(gpui::FontWeight::SEMIBOLD)
                                .child(preview.title()),
                        )
                        .child(
                            div()
                                .text_sm()
                                .text_color(rgb(theme.text_muted))
                                .child(preview.description()),
                        ),
                )
                .child(
                    div()
                        .flex_none()
                        .px_2()
                        .py_1()
                        .border_1()
                        .border_color(rgb(theme.border))
                        .rounded(px(2.0))
                        .font_family("Menlo")
                        .text_xs()
                        .text_color(rgb(theme.accent))
                        .child(preview.group()),
                ),
        )
        .child(
            div()
                .min_h(px(420.0))
                .p_8()
                .flex()
                .items_center()
                .justify_center()
                .bg(rgb(theme.canvas))
                .child(kit_preview_content(preview, theme)),
        )
}

fn kit_preview_content(preview: KitPreview, theme: Theme) -> gpui::AnyElement {
    match preview {
        KitPreview::Accordion => div()
            .w_full()
            .max_w(px(620.0))
            .child(
                Accordion::new("preview-accordion")
                    .item(|item| {
                        item.open(true).title("Workspace model").child(
                            "Repositories, worktrees, knowledge, and tools share one managed root.",
                        )
                    })
                    .item(|item| {
                        item.title("Local persistence").child(
                            "SQLite data remains in the platform application-data directory.",
                        )
                    }),
            )
            .into_any_element(),
        KitPreview::Alert => div()
            .w_full()
            .max_w(px(640.0))
            .flex()
            .flex_col()
            .gap_3()
            .child(Alert::info(
                "preview-alert-info",
                "Environment metadata is available.",
            ))
            .child(Alert::success(
                "preview-alert-success",
                "Workspace index is current.",
            ))
            .child(Alert::warning(
                "preview-alert-warning",
                "Two tasks need attention.",
            ))
            .child(Alert::error(
                "preview-alert-error",
                "The last command failed.",
            ))
            .into_any_element(),
        KitPreview::Avatar => div()
            .flex()
            .items_end()
            .gap_4()
            .child(Avatar::new().name("Ada Lovelace").small())
            .child(Avatar::new().name("Grace Hopper"))
            .child(Avatar::new().name("Margaret Hamilton").large())
            .child(Avatar::new().placeholder(IconName::Bot).large())
            .into_any_element(),
        KitPreview::Badge => div()
            .flex()
            .items_center()
            .gap_5()
            .child(
                Badge::new()
                    .count(3)
                    .child(Button::new("preview-badge-tasks").label("Tasks")),
            )
            .child(
                Badge::new()
                    .count(12)
                    .child(Button::new("preview-badge-events").ghost().label("Events")),
            )
            .into_any_element(),
        KitPreview::Breadcrumb => Breadcrumb::new()
            .child("Workspaces")
            .child("unshell")
            .child("Repositories")
            .into_any_element(),
        KitPreview::Button => div()
            .flex()
            .flex_wrap()
            .items_center()
            .justify_center()
            .gap_3()
            .child(Button::new("preview-primary").primary().label("Run"))
            .child(Button::new("preview-secondary").secondary().label("Review"))
            .child(Button::new("preview-success").success().label("Passed"))
            .child(Button::new("preview-warning").warning().label("Retry"))
            .child(Button::new("preview-danger").danger().label("Stop"))
            .child(Button::new("preview-ghost").ghost().label("More"))
            .child(Button::new("preview-link").link().label("Details"))
            .into_any_element(),
        KitPreview::Checkbox => div()
            .flex()
            .flex_col()
            .gap_4()
            .child(
                Checkbox::new("preview-checkbox-on")
                    .checked(true)
                    .label("Format on save"),
            )
            .child(Checkbox::new("preview-checkbox-off").label("Run tests before commit"))
            .child(
                Checkbox::new("preview-checkbox-disabled")
                    .checked(true)
                    .disabled(true)
                    .label("Managed by workspace policy"),
            )
            .into_any_element(),
        KitPreview::GroupBox => GroupBox::new()
            .outline()
            .title("Agent permissions")
            .child(
                Checkbox::new("preview-group-files")
                    .checked(true)
                    .label("Read workspace files"),
            )
            .child(
                Checkbox::new("preview-group-commands")
                    .checked(true)
                    .label("Run approved commands"),
            )
            .child(Checkbox::new("preview-group-network").label("Access the network"))
            .into_any_element(),
        KitPreview::Icon => div()
            .flex()
            .items_center()
            .gap_5()
            .child(Icon::new(IconName::Folder).large())
            .child(Icon::new(IconName::Github).large())
            .child(Icon::new(IconName::SquareTerminal).large())
            .child(Icon::new(IconName::Bot).large())
            .child(Icon::new(IconName::CircleCheck).large())
            .into_any_element(),
        KitPreview::Kbd => div()
            .flex()
            .items_center()
            .gap_3()
            .child(Kbd::new(Keystroke::parse("cmd-shift-p").unwrap()))
            .child(Kbd::new(Keystroke::parse("cmd-k").unwrap()).outline())
            .child(Kbd::new(Keystroke::parse("escape").unwrap()))
            .child(Kbd::new(Keystroke::parse("enter").unwrap()))
            .into_any_element(),
        KitPreview::Label => div()
            .w(px(420.0))
            .flex()
            .flex_col()
            .gap_4()
            .child(Label::new("main.rs").secondary("modified · 2m"))
            .child(Label::new("workspace.db").secondary("clean · local"))
            .child(Label::new("flake.nix").secondary("tracked"))
            .into_any_element(),
        KitPreview::Link => div()
            .flex()
            .items_center()
            .gap_5()
            .child(Link::new("preview-link-docs").child("Open documentation"))
            .child(Link::new("preview-link-diff").child("Review changes"))
            .child(
                Link::new("preview-link-disabled")
                    .disabled(true)
                    .child("Unavailable"),
            )
            .into_any_element(),
        KitPreview::Pagination => Pagination::new("preview-pagination")
            .current_page(4)
            .total_pages(12)
            .visible_pages(7)
            .into_any_element(),
        KitPreview::Progress => div()
            .w_full()
            .max_w(px(560.0))
            .flex()
            .flex_col()
            .gap_5()
            .child(
                div()
                    .flex()
                    .justify_between()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.text_muted))
                    .child("INDEXING WORKSPACE")
                    .child("72%"),
            )
            .child(Progress::new("preview-progress").value(72.0))
            .into_any_element(),
        KitPreview::Radio => div()
            .flex()
            .flex_col()
            .gap_4()
            .child(
                Radio::new("preview-radio-local")
                    .checked(true)
                    .label("Local"),
            )
            .child(Radio::new("preview-radio-remote").label("Remote"))
            .child(Radio::new("preview-radio-cloud").label("Cloud"))
            .into_any_element(),
        KitPreview::Rating => Rating::new("preview-rating")
            .value(4)
            .max(5)
            .large()
            .into_any_element(),
        KitPreview::Separator => div()
            .w(px(520.0))
            .flex()
            .flex_col()
            .gap_5()
            .child(Separator::horizontal())
            .child(Separator::horizontal().label("WORKTREE"))
            .child(Separator::horizontal().label("OR"))
            .into_any_element(),
        KitPreview::Stepper => Stepper::new("preview-stepper")
            .w(px(620.0))
            .selected_index(1)
            .items([
                StepperItem::new().child("Configure"),
                StepperItem::new().child("Review"),
                StepperItem::new().child("Create"),
            ])
            .into_any_element(),
        KitPreview::Switch => div()
            .flex()
            .flex_col()
            .gap_4()
            .child(
                Switch::new("preview-switch-on")
                    .checked(true)
                    .label("Agent access"),
            )
            .child(Switch::new("preview-switch-off").label("Background indexing"))
            .into_any_element(),
        KitPreview::Tab => TabBar::new("preview-tabs")
            .w(px(620.0))
            .selected_index(0)
            .child(Tab::new().label("Overview"))
            .child(Tab::new().label("Repositories"))
            .child(Tab::new().label("Knowledge"))
            .child(Tab::new().label("Settings"))
            .into_any_element(),
        KitPreview::Tag => div()
            .flex()
            .flex_wrap()
            .items_center()
            .gap_3()
            .child(Tag::primary().child("ACTIVE"))
            .child(Tag::success().outline().child("CLEAN"))
            .child(Tag::warning().outline().child("2 WARNINGS"))
            .child(Tag::danger().outline().child("FAILED"))
            .into_any_element(),
        KitPreview::Toggle => div()
            .flex()
            .items_center()
            .gap_3()
            .child(
                Toggle::new("preview-toggle-follow")
                    .checked(true)
                    .label("FOLLOW"),
            )
            .child(Toggle::new("preview-toggle-pin").label("PIN"))
            .child(
                Toggle::new("preview-toggle-lock")
                    .checked(true)
                    .label("LOCK"),
            )
            .into_any_element(),
        KitPreview::Shimmer => div()
            .w_full()
            .max_w(px(520.0))
            .flex()
            .flex_col()
            .gap_4()
            .font_family("Menlo")
            .text_color(rgb(theme.text_muted))
            .child(
                ShimmerText::new("Thinking through the workspace…")
                    .w_full()
                    .highlight_color(gpui::Hsla::from(rgb(theme.accent)))
                    .spread(0.18),
            )
            .child(
                ShimmerText::new("Searching indexed files…")
                    .w_full()
                    .highlight_color(gpui::Hsla::from(rgb(theme.success)))
                    .spread(0.18)
                    .reverse(true),
            )
            .into_any_element(),
        KitPreview::Skeleton => div()
            .w(px(420.0))
            .flex()
            .items_center()
            .gap_3()
            .child(Skeleton::new().size(px(48.0)).rounded_full())
            .child(
                div()
                    .flex_1()
                    .flex()
                    .flex_col()
                    .gap_2()
                    .child(Skeleton::new().w_full().h(px(12.0)))
                    .child(Skeleton::new().w_2_3().h(px(12.0)).secondary()),
            )
            .into_any_element(),
        KitPreview::Spinner => div()
            .flex()
            .items_center()
            .gap_6()
            .child(Spinner::new().small())
            .child(Spinner::new())
            .child(
                Spinner::new()
                    .large()
                    .color(gpui::Hsla::from(rgb(theme.accent))),
            )
            .into_any_element(),
    }
}

fn workspace_switcher_card(theme: Theme) -> impl IntoElement {
    specimen_card(
        theme,
        "WORKSPACE / SWITCHER",
        div()
            .w_full()
            .px_2()
            .py_2()
            .flex()
            .items_center()
            .gap_2()
            .border_1()
            .border_color(rgb(theme.border))
            .bg(rgb(theme.canvas))
            .rounded(px(2.0))
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
                    .child("unshell"),
            )
            .child(
                div()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.text_muted))
                    .child("⌄"),
            ),
        "The sidebar starts with persistent workspace identity and one compact switching affordance.",
    )
}

fn workspace_row_card(theme: Theme) -> impl IntoElement {
    specimen_card(
        theme,
        "WORKSPACE / INDEX ROW",
        div()
            .w_full()
            .px_3()
            .py_2()
            .flex()
            .items_center()
            .gap_3()
            .border_1()
            .border_color(rgb(theme.border))
            .bg(rgb(theme.canvas))
            .rounded(px(2.0))
            .child(
                div()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.accent))
                    .child("01"),
            )
            .child(
                div()
                    .flex_1()
                    .flex()
                    .flex_col()
                    .gap_1()
                    .child(div().text_sm().child("unshell"))
                    .child(
                        div()
                            .font_family("Menlo")
                            .text_xs()
                            .text_color(rgb(theme.text_muted))
                            .child("~/Developer/unshell"),
                    ),
            )
            .child(
                div()
                    .font_family("Menlo")
                    .text_xs()
                    .text_color(rgb(theme.success))
                    .child("READY"),
            ),
        "Indexed rows prioritize workspace identity, filesystem evidence, and current state.",
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
            "03 // SYSTEM STATUS",
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
}

fn page_footer(theme: Theme, label: &'static str) -> impl IntoElement {
    div()
        .pt_6()
        .pb_3()
        .border_t_1()
        .border_color(rgb(theme.border))
        .text_xs()
        .font_family("Menlo")
        .text_color(rgb(theme.text_muted))
        .child(label)
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

#[cfg(test)]
mod tests {
    use std::collections::HashSet;

    use super::{DevPage, KitPreview};

    #[test]
    fn developer_pages_have_stable_unique_menu_entries() {
        assert_eq!(DevPage::ALL, [DevPage::GpuiKit, DevPage::UnshellUi]);
        assert_ne!(DevPage::GpuiKit.title(), DevPage::UnshellUi.title());
        assert_ne!(
            DevPage::GpuiKit.menu_description(),
            DevPage::UnshellUi.menu_description()
        );
    }

    #[test]
    fn kit_gallery_has_a_unique_preview_for_every_registered_primitive() {
        let titles = KitPreview::ALL
            .into_iter()
            .map(KitPreview::title)
            .collect::<Vec<_>>();
        let unique = titles.iter().copied().collect::<HashSet<_>>();

        assert_eq!(titles.len(), 25);
        assert_eq!(unique.len(), titles.len());
    }
}

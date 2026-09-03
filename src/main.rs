#[cfg(debug_assertions)]
mod design_system;
mod theme;

use gpui::{
    App, Application, Bounds, Context, Render, TitlebarOptions, Window, WindowBounds,
    WindowControlArea, WindowDecorations, WindowOptions, div, point, prelude::*, px, rgb, size,
};
use theme::{Theme, ThemeId};

pub(crate) struct Workspace {
    theme: ThemeId,
    #[cfg(debug_assertions)]
    show_design_system: bool,
}

impl Workspace {
    fn theme(&self) -> Theme {
        self.theme.theme()
    }

    #[cfg(debug_assertions)]
    pub(crate) fn select_theme(&mut self, theme: ThemeId, cx: &mut Context<Self>) {
        self.theme = theme;
        cx.notify();
    }

    #[cfg(debug_assertions)]
    pub(crate) fn close_design_system(&mut self, cx: &mut Context<Self>) {
        self.show_design_system = false;
        cx.notify();
    }
}

impl Render for Workspace {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = self.theme();

        #[cfg(debug_assertions)]
        if self.show_design_system {
            let page = design_system::design_system_page(self.theme, cx);
            return app_frame(theme, window, cx, page).into_any_element();
        }

        app_frame(theme, window, cx, workspace_home(theme)).into_any_element()
    }
}

fn app_frame(
    theme: Theme,
    window: &Window,
    cx: &mut Context<Workspace>,
    content: impl IntoElement,
) -> impl IntoElement {
    div()
        .size_full()
        .flex()
        .flex_col()
        .bg(rgb(theme.canvas))
        .text_color(rgb(theme.text))
        .child(custom_title_bar(theme, window.is_window_active(), cx))
        .child(content)
}

fn custom_title_bar(
    theme: Theme,
    is_window_active: bool,
    cx: &mut Context<Workspace>,
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

fn workspace_home(theme: Theme) -> impl IntoElement {
    div()
        .flex_1()
        .w_full()
        .flex()
        .flex_col()
        .items_center()
        .justify_center()
        .gap_3()
        .bg(rgb(theme.canvas))
        .text_color(rgb(theme.text))
        .child(div().font_family("Georgia").text_3xl().child("Unshell"))
        .child(
            div()
                .text_lg()
                .text_color(rgb(theme.text_muted))
                .child("Your developer workspace for agentic coding."),
        )
        .child(
            div()
                .text_sm()
                .text_color(rgb(theme.text_muted))
                .child("Native desktop foundation · Rust + GPUI"),
        )
}

fn main() {
    Application::new().run(|cx: &mut App| {
        let bounds = Bounds::centered(None, size(px(1_200.0), px(760.0)), cx);

        cx.open_window(
            WindowOptions {
                window_bounds: Some(WindowBounds::Windowed(bounds)),
                window_min_size: Some(size(px(800.0), px(500.0))),
                titlebar: Some(TitlebarOptions {
                    title: Some("Unshell".into()),
                    appears_transparent: true,
                    traffic_light_position: Some(point(px(14.0), px(12.0))),
                }),
                // Linux compositors may choose to ignore this request, but it
                // opts into the app-drawn bar whenever client decorations are
                // supported.
                window_decorations: Some(WindowDecorations::Client),
                ..Default::default()
            },
            |_window, cx| {
                cx.new(|_| Workspace {
                    theme: ThemeId::UnshellDark,
                    #[cfg(debug_assertions)]
                    show_design_system: false,
                })
            },
        )
        .expect("failed to open the Unshell window");

        cx.activate(true);
    });
}

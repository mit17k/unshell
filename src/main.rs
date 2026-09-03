use gpui::{
    App, Application, Bounds, Context, Render, TitlebarOptions, Window, WindowBounds,
    WindowOptions, div, prelude::*, px, rgb, size,
};

struct Workspace;

impl Render for Workspace {
    fn render(&mut self, _window: &mut Window, _cx: &mut Context<Self>) -> impl IntoElement {
        div()
            .size_full()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap_3()
            .bg(rgb(0x101216))
            .text_color(rgb(0xe8eaed))
            .child(div().text_2xl().child("Unshell"))
            .child(
                div()
                    .text_lg()
                    .text_color(rgb(0xc4c7c5))
                    .child("Your developer workspace for agentic coding."),
            )
            .child(
                div()
                    .text_sm()
                    .text_color(rgb(0x8e918f))
                    .child("Native desktop foundation · Rust + GPUI"),
            )
    }
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
                    ..Default::default()
                }),
                ..Default::default()
            },
            |_window, cx| cx.new(|_| Workspace),
        )
        .expect("failed to open the Unshell window");

        cx.activate(true);
    });
}

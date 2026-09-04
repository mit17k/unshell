#[cfg(debug_assertions)]
mod design_system;
mod root;
mod workspace_list;
mod workspace_setup;

use std::sync::Arc;

use gpui::{
    App, AppContext, Bounds, TitlebarOptions, WindowBounds, WindowDecorations, WindowOptions,
    point, px, size,
};
use unshell_local::LocalWorkspaceService;

pub use root::RootView;

pub fn run(cx: &mut App) {
    unshell_ui::register_text_input_key_bindings(cx);

    let startup = LocalWorkspaceService::open_default()
        .and_then(|service| {
            let service = Arc::new(service);
            let workspaces = service.list_ready()?;
            Ok((service, workspaces))
        })
        .map_err(|error| error.to_string());

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
            window_decorations: Some(WindowDecorations::Client),
            ..Default::default()
        },
        |_window, cx| cx.new(|cx| RootView::new(startup, cx)),
    )
    .expect("failed to open the Unshell window");

    cx.activate(true);
}

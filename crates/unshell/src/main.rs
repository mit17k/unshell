use gpui_kit::App;

fn main() {
    gpui_kit::application()
        .with_assets(gpui_kit::assets::Assets)
        .run(|cx: &mut App| unshell_app::run(cx));
}

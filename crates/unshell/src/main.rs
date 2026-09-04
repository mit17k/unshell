use gpui::{App, Application};

fn main() {
    Application::new().run(|cx: &mut App| unshell_app::run(cx));
}

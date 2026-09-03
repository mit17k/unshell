use iced::widget::{column, container, text};
use iced::{Element, Fill, Theme};

pub fn main() -> iced::Result {
    iced::application(Workspace::default, update, view)
        .title("Unshell")
        .theme(theme)
        .window_size((1_200.0, 760.0))
        .centered()
        .run()
}

#[derive(Default)]
struct Workspace;

#[derive(Debug, Clone)]
enum Message {}

fn update(_workspace: &mut Workspace, message: Message) {
    match message {}
}

fn theme(_workspace: &Workspace) -> Theme {
    Theme::Dark
}

fn view(_workspace: &Workspace) -> Element<'_, Message> {
    let introduction = column![
        text("Unshell").size(44),
        text("Your developer workspace for agentic coding.").size(22),
        text("Native desktop foundation · Rust + iced").size(14),
    ]
    .spacing(12);

    container(introduction).center(Fill).into()
}

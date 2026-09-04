mod text_input;
mod theme;

/// GPUI Kit's styled component library, re-exported through the UI crate so
/// application features do not need to own a second design-system boundary.
pub use gpui_kit::component;
pub use text_input::{Changed, TextInput, register_text_input_key_bindings};
pub use theme::{Theme, ThemeId};

use gpui::{App, Hsla, rgb};
use gpui_kit::component::{Theme as KitTheme, ThemeMode, ThemeTokens};

/// Semantic visual roles. Application components use these names instead of
/// choosing literal colours, which keeps themes replaceable and extensible.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Theme {
    pub name: &'static str,
    pub description: &'static str,
    pub canvas: u32,
    pub surface: u32,
    pub surface_raised: u32,
    pub text: u32,
    pub text_muted: u32,
    pub border: u32,
    pub accent: u32,
    pub accent_text: u32,
    pub success: u32,
    pub warning: u32,
    pub danger: u32,
}

impl Theme {
    /// Projects Unshell's deliberately small semantic palette onto GPUI Kit's
    /// richer token set. Kit remains responsible for component behavior while
    /// Unshell remains responsible for presentation.
    pub fn apply_to_gpui_kit(self, cx: &mut App) {
        let color = |value| Hsla::from(rgb(value));
        let kit = KitTheme::global_mut(cx);

        kit.mode = ThemeMode::Dark;
        kit.font_family = "System UI".into();
        kit.mono_font_family = "Menlo".into();
        kit.radius = gpui::px(2.0);
        kit.radius_lg = gpui::px(2.0);
        kit.shadow = false;

        kit.background = color(self.canvas);
        kit.foreground = color(self.text);
        kit.border = color(self.border);
        kit.input = color(self.border);
        kit.caret = color(self.accent);
        kit.ring = color(self.accent);
        kit.selection = color(self.accent).alpha(0.28);

        kit.muted = color(self.surface);
        kit.muted_foreground = color(self.text_muted);
        kit.accent = color(self.surface_raised);
        kit.accent_foreground = color(self.text);
        kit.popover = color(self.surface_raised);
        kit.popover_foreground = color(self.text);
        kit.secondary = color(self.surface_raised);
        kit.secondary_foreground = color(self.text);
        kit.sidebar = color(self.surface);
        kit.sidebar_foreground = color(self.text);
        kit.sidebar_border = color(self.border);
        kit.sidebar_accent = color(self.surface_raised);
        kit.sidebar_accent_foreground = color(self.text);

        kit.primary = color(self.accent);
        kit.primary_foreground = color(self.accent_text);
        kit.button_primary = color(self.accent);
        kit.button_primary_foreground = color(self.accent_text);
        kit.button = color(self.surface_raised);
        kit.button_hover = color(self.surface_raised);
        kit.button_active = color(self.surface);
        kit.button_foreground = color(self.text);
        kit.button_secondary = color(self.surface_raised);
        kit.button_secondary_hover = color(self.surface_raised);
        kit.button_secondary_active = color(self.surface);
        kit.button_secondary_foreground = color(self.text);
        kit.button_primary_hover = color(self.accent);
        kit.button_primary_active = color(self.accent);

        kit.success = color(self.success);
        kit.success_hover = color(self.success);
        kit.success_active = color(self.success);
        kit.success_foreground = color(self.canvas);
        kit.warning = color(self.warning);
        kit.warning_hover = color(self.warning);
        kit.warning_active = color(self.warning);
        kit.warning_foreground = color(self.canvas);
        kit.danger = color(self.danger);
        kit.danger_hover = color(self.danger);
        kit.danger_active = color(self.danger);
        kit.danger_foreground = color(self.canvas);
        kit.info = color(self.accent);
        kit.info_hover = color(self.accent);
        kit.info_active = color(self.accent);
        kit.info_foreground = color(self.accent_text);

        kit.button_success = color(self.success);
        kit.button_success_hover = color(self.success);
        kit.button_success_active = color(self.success);
        kit.button_success_foreground = color(self.canvas);
        kit.button_warning = color(self.warning);
        kit.button_warning_hover = color(self.warning);
        kit.button_warning_active = color(self.warning);
        kit.button_warning_foreground = color(self.canvas);
        kit.button_danger = color(self.danger);
        kit.button_danger_hover = color(self.danger);
        kit.button_danger_active = color(self.danger);
        kit.button_danger_foreground = color(self.canvas);
        kit.button_info = color(self.accent);
        kit.button_info_hover = color(self.accent);
        kit.button_info_active = color(self.accent);
        kit.button_info_foreground = color(self.accent_text);

        kit.accordion = color(self.surface);
        kit.group_box = color(self.surface);
        kit.group_box_foreground = color(self.text);
        kit.description_list_label = color(self.surface_raised);
        kit.description_list_label_foreground = color(self.text_muted);
        kit.drag_border = color(self.accent);
        kit.drop_target = color(self.surface_raised);
        kit.link = color(self.accent);
        kit.link_hover = color(self.accent);
        kit.link_active = color(self.accent);

        kit.colors.list = color(self.surface);
        kit.colors.list_even = color(self.surface);
        kit.colors.list_head = color(self.surface_raised);
        kit.colors.list_hover = color(self.surface_raised);
        kit.colors.list_active = color(self.surface_raised);
        kit.colors.list_active_border = color(self.accent);
        kit.table = color(self.surface);
        kit.table_even = color(self.surface);
        kit.table_head = color(self.surface_raised);
        kit.table_head_foreground = color(self.text_muted);
        kit.table_foot = color(self.surface_raised);
        kit.table_foot_foreground = color(self.text_muted);
        kit.table_hover = color(self.surface_raised);
        kit.table_active = color(self.surface_raised);
        kit.table_active_border = color(self.accent);
        kit.table_row_border = color(self.border);

        kit.progress_bar = color(self.accent);
        kit.scrollbar = color(self.canvas).alpha(0.0);
        kit.scrollbar_thumb = color(self.border);
        kit.scrollbar_thumb_hover = color(self.text_muted);
        kit.skeleton = color(self.surface_raised);
        kit.slider_bar = color(self.accent);
        kit.slider_thumb = color(self.text);
        kit.switch = color(self.border);
        kit.switch_thumb = color(self.text);

        kit.tab = color(self.surface);
        kit.tab_foreground = color(self.text_muted);
        kit.tab_active = color(self.surface_raised);
        kit.tab_active_foreground = color(self.text);
        kit.tab_bar = color(self.surface);
        kit.tab_bar_segmented = color(self.canvas);
        kit.title_bar = color(self.surface);
        kit.title_bar_border = color(self.border);
        kit.status_bar = color(self.surface);
        kit.status_bar_border = color(self.border);
        kit.tiles = color(self.surface);
        kit.window_border = color(self.border);
        kit.overlay = color(self.canvas).alpha(0.72);

        kit.sidebar_primary = color(self.accent);
        kit.sidebar_primary_foreground = color(self.accent_text);
        kit.chart_1 = color(self.accent);
        kit.chart_2 = color(self.success);
        kit.chart_3 = color(self.warning);
        kit.chart_4 = color(self.danger);
        kit.chart_5 = color(self.text_muted);
        kit.chart_bullish = color(self.success);
        kit.chart_bearish = color(self.danger);
        kit.red = color(self.danger);
        kit.red_light = color(self.danger);
        kit.green = color(self.success);
        kit.green_light = color(self.success);
        kit.blue = color(self.accent);
        kit.blue_light = color(self.accent);
        kit.yellow = color(self.warning);
        kit.yellow_light = color(self.warning);
        kit.magenta = color(self.accent);
        kit.magenta_light = color(self.accent);
        kit.cyan = color(self.accent);
        kit.cyan_light = color(self.accent);

        // Legacy component-specific tokens are derived from the same semantic
        // colors, then mirrored into gpui-base for scroll and resize behavior.
        kit.tokens = ThemeTokens::from(&kit.colors);
        KitTheme::sync_base(cx);
    }
}

#[cfg_attr(not(debug_assertions), allow(dead_code))]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ThemeId {
    UnshellDark,
    Dracula,
    CatppuccinMocha,
    Nord,
    TokyoNight,
    GitHubDark,
}

#[cfg_attr(not(debug_assertions), allow(dead_code))]
impl ThemeId {
    pub const ALL: [Self; 6] = [
        Self::UnshellDark,
        Self::Dracula,
        Self::CatppuccinMocha,
        Self::Nord,
        Self::TokyoNight,
        Self::GitHubDark,
    ];

    pub fn theme(self) -> Theme {
        match self {
            Self::UnshellDark => Theme {
                name: "Unshell Dark",
                description: "The restrained default for the developer workspace.",
                canvas: 0x0b0d0f,
                surface: 0x111418,
                surface_raised: 0x171b20,
                text: 0xe7e2d9,
                text_muted: 0xa9a39a,
                border: 0x3b3d3d,
                accent: 0xd7c6a3,
                accent_text: 0x15130f,
                success: 0x9bc49b,
                warning: 0xe0b56f,
                danger: 0xdd8c8c,
            },
            Self::Dracula => Theme {
                name: "Dracula",
                description: "A familiar purple-forward editor theme.",
                canvas: 0x282a36,
                surface: 0x303241,
                surface_raised: 0x3a3c4e,
                text: 0xf8f8f2,
                text_muted: 0xb8b8c5,
                border: 0x55586d,
                accent: 0xbd93f9,
                accent_text: 0x282a36,
                success: 0x50fa7b,
                warning: 0xf1fa8c,
                danger: 0xff5555,
            },
            Self::CatppuccinMocha => Theme {
                name: "Catppuccin Mocha",
                description: "A soft, low-glare theme with clear semantic contrast.",
                canvas: 0x1e1e2e,
                surface: 0x252536,
                surface_raised: 0x313244,
                text: 0xcdd6f4,
                text_muted: 0xa6adc8,
                border: 0x585b70,
                accent: 0xcba6f7,
                accent_text: 0x1e1e2e,
                success: 0xa6e3a1,
                warning: 0xf9e2af,
                danger: 0xf38ba8,
            },
            Self::Nord => Theme {
                name: "Nord",
                description: "A cool, calm palette inspired by arctic landscapes.",
                canvas: 0x2e3440,
                surface: 0x353c4a,
                surface_raised: 0x3b4252,
                text: 0xeceff4,
                text_muted: 0xd8dee9,
                border: 0x4c566a,
                accent: 0x88c0d0,
                accent_text: 0x2e3440,
                success: 0xa3be8c,
                warning: 0xebcb8b,
                danger: 0xbf616a,
            },
            Self::TokyoNight => Theme {
                name: "Tokyo Night",
                description: "A deep blue editor theme with vivid but controlled accents.",
                canvas: 0x1a1b26,
                surface: 0x1f2335,
                surface_raised: 0x292e42,
                text: 0xc0caf5,
                text_muted: 0x9aa5ce,
                border: 0x3b4261,
                accent: 0x7aa2f7,
                accent_text: 0x1a1b26,
                success: 0x9ece6a,
                warning: 0xe0af68,
                danger: 0xf7768e,
            },
            Self::GitHubDark => Theme {
                name: "GitHub Dark",
                description: "GitHub's familiar high-clarity dark workspace treatment.",
                canvas: 0x0d1117,
                surface: 0x161b22,
                surface_raised: 0x21262d,
                text: 0xc9d1d9,
                text_muted: 0x8b949e,
                border: 0x30363d,
                accent: 0x58a6ff,
                accent_text: 0x0d1117,
                success: 0x3fb950,
                warning: 0xd29922,
                danger: 0xf85149,
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::ThemeId;

    #[test]
    fn bundled_themes_have_unique_names_and_canvases() {
        let themes = ThemeId::ALL.map(ThemeId::theme);
        for (index, theme) in themes.iter().enumerate() {
            assert!(
                themes[..index]
                    .iter()
                    .all(|other| other.name != theme.name && other.canvas != theme.canvas)
            );
        }
    }
}

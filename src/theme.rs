/// Semantic visual roles. Application components use these names instead of
/// choosing literal colours, which keeps themes replaceable and extensible.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) struct Theme {
    pub(crate) name: &'static str,
    pub(crate) description: &'static str,
    pub(crate) canvas: u32,
    pub(crate) surface: u32,
    pub(crate) surface_raised: u32,
    pub(crate) text: u32,
    pub(crate) text_muted: u32,
    pub(crate) border: u32,
    pub(crate) accent: u32,
    pub(crate) accent_text: u32,
    pub(crate) success: u32,
    pub(crate) warning: u32,
    pub(crate) danger: u32,
}

#[cfg_attr(not(debug_assertions), allow(dead_code))]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) enum ThemeId {
    UnshellDark,
    Dracula,
    CatppuccinMocha,
    Nord,
    TokyoNight,
    GitHubDark,
}

#[cfg_attr(not(debug_assertions), allow(dead_code))]
impl ThemeId {
    pub(crate) const ALL: [Self; 6] = [
        Self::UnshellDark,
        Self::Dracula,
        Self::CatppuccinMocha,
        Self::Nord,
        Self::TokyoNight,
        Self::GitHubDark,
    ];

    pub(crate) fn theme(self) -> Theme {
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

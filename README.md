# kosm_equibop

Equibop for kosm: a local theme, `kosm.theme.css`, recoloring
[Material Discord](https://github.com/CapnKitten/Material-Discord) with the theme's colors, font
and rounding.

The app writes the whole file `<directory>/themes/kosm.theme.css`, so do not edit it. Once, in
Equibop's settings: keep Material Discord on among the online themes
(`https://capnkitten.github.io/BetterDiscord/Themes/Material-Discord/css/source.css`), and turn
`kosm.theme.css` on among the local themes. Equibop applies a changed theme at once. `kosm doctor`
checks that Equibop is installed, natively or as a Flatpak, and that `kosm.theme.css` is on in
`<directory>/settings/settings.json`.

Equibop applies its themes in this order, the later winning: online themes, local themes,
QuickCSS. So your QuickCSS still overrides the theme; delete the variables you set there that the
theme now sets. The theme also defines its values as `--kosm-*` custom properties (the color
names below with `_` as `-`, and `--kosm-font`), for your QuickCSS to use.

`from(theme)` sets the backgrounds from the theme's background role with its background alpha
and its surface and state steps, the text from the foreground role, links and the accent from
their roles, text on the accent from the opaque background role, and outlines the theme's
`line.border` of the accent. The font and rounding are left at their defaults.

## Fields

| Field | Written as | Default |
|---|---|---|
| `directory` | | the Flatpak's `~/.var/app/org.equicord.equibop/config/equibop`; a native Equibop uses `~/.config/equibop` |
| `format` | | the CSS adapter's: `#rrggbbaa` |
| `colors.background` | `--app-bg`, the window's background, painted once: Material Discord's channel list and chat backgrounds (`--main-color`, `--main-alt`, `--chat-color`) are made clear, as it stacks them | |
| `colors.background_alt` | side panels, the status picker, messages, popouts, cards, inputs, tooltips | |
| `colors.background_highlight` | hovered and selected messages, cards and menu items | |
| `colors.text` | `--text-normal`, input and menu text, the scrollbar | |
| `colors.text_highlight` | headings and card headers | |
| `colors.placeholder` | input placeholders, muted and disabled text | |
| `colors.link` | `--text-link`, link buttons | |
| `colors.accent` | `--accent-hsl` (its hue, saturation and lightness; no alpha), `--text-brand` | |
| `colors.accent_text` | `--accent-text-color` | |
| `colors.outline` | borders and separators | |
| `font` | `--app-font`, quoted; quotes, backslashes and line breaks are an error | `"Google Sans Flex"`, Material Discord's |
| `rounding` | the radii of messages, media, the text area, popouts, cards, buttons, inputs, tooltips and side panels in pixels; side panels' small radius is half | null: Material Discord's own |

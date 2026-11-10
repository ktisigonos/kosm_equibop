# kosm_equibop

Equibop for kosm: the theme's colors and font as CSS custom properties in Equibop's QuickCSS,
for a Discord theme such as Material Discord to use.

The app writes a block between `/* kosm:begin kosm */` and `/* kosm:end */` at the end of
`~/.config/equibop/settings/quickCss.css`: a `:root` rule of `--kosm-*` properties. The rest
of the file stays yours, byte for byte. Your own CSS then uses them, and Equibop applies a
changed QuickCSS at once:

```css
.theme-dark {
	--background-col: var(--kosm-background);
	--text-col: var(--kosm-text);
	--app-font: var(--kosm-font);
}
```

`from(theme)` sets the backgrounds from black (white in light mode) with the theme's
background alpha and its surface and state steps, the text from white, links and the accent
cyan, and outlines the theme's `line.border` of cyan. The font is left alone.

## Fields

| Field | Written as | Default |
|---|---|---|
| `file` | | `~/.config/equibop/settings/quickCss.css`, created when missing |
| `format` | | the CSS adapter's: `#rrggbbaa` |
| `colors.background` | `--kosm-background` | null: not written |
| `colors.background_alt` | `--kosm-background-alt` | null |
| `colors.background_highlight` | `--kosm-background-highlight` | null |
| `colors.text` | `--kosm-text` | null |
| `colors.text_highlight` | `--kosm-text-highlight` | null |
| `colors.placeholder` | `--kosm-placeholder` | null |
| `colors.link` | `--kosm-link` | null |
| `colors.accent` | `--kosm-accent` | null |
| `colors.outline` | `--kosm-outline` | null |
| `font` | `--kosm-font`, quoted | null |
